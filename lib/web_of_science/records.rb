require 'forwardable'

module WebOfScience

  # Utilities for working with Web of Science records
  class Records
    extend Forwardable
    include Enumerable

    # @return [Integer] WOS record count
    def_delegators :rec_nodes, :count

    # @return [Boolean] WOS records empty?
    def_delegators :rec_nodes, :empty?

    # @return [WebOfScience::Record]
    def_delegators :to_a, :sample

    # @return [String] WOS records in XML
    def_delegators :doc, :to_xml

    # @!attribute [r] doc
    #   @return [Nokogiri::XML::Document] WOS records document
    attr_reader :doc

    # JSON will be converted to old SOAP XML
    # @param xml [String] records in XML
    # @param json [String] records in JSON
    def initialize(xml: nil, json: nil)
      raise(ArgumentError, 'xml and json cannot both be nil') if xml.nil? && json.nil?
      raise(ArgumentError, 'Only one of xml or json may be used to construct a WOS Record') unless xml.nil? || json.nil?
      @doc = WebOfScience::XmlParser.parse(xml, nil) unless (xml.nil?)
      @doc = json_to_xml(json) unless (json.nil?)
    end

    # Conver newer REST JSON response to SOAP XML format
    # @param json [String] records in JSON
    def json_to_xml(json)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.return {
          json['Data']['Records']['records']['REC'].each do |rec|
            atitle = rec['static_data']['summary']['titles']['title'].select { |title| title['type'] == 'item' }.first
            jtitle = rec['static_data']['summary']['titles']['title'].select { |title| title['type'] == 'source' }.first
            doi = rec['dynamic_data']['cluster_related']['identifiers']['identifier'].select { |identifier| identifier['type'] == 'doi' }.first
            issn = rec['dynamic_data']['cluster_related']['identifiers']['identifier'].select { |identifier| identifier['type'] == 'issn' }.first
            eissn = rec['dynamic_data']['cluster_related']['identifiers']['identifier'].select { |identifier| identifier['type'] == 'eissn' }.first

            xml.records {
              xml.uid rec['UID']
              xml.title {
                xml.label 'Title'
                xml.value atitle['content']
              } unless atitle.nil?
              xml.doctype {
                xml.label 'Doctype'
                xml.value rec['static_data']['summary']['doctypes']['doctype']
              }
              xml.source {
                xml.label 'Issue'
                xml.value rec['static_data']['summary']['pub_info']['issue']
              }
              xml.source {
                xml.label 'Pages'
                xml.value rec['static_data']['summary']['pub_info']['page']['content']
              }
              xml.source {
                xml.label 'Published.BiblioDate'
                xml.value rec['static_data']['summary']['pub_info']['pubmonth']
              }
              xml.source {
                xml.label 'Published.BiblioYear'
                xml.value rec['static_data']['summary']['pub_info']['pubyear']
              }
              xml.source {
                xml.label 'SourceTitle'
                xml.value jtitle['content']
              } unless jtitle.nil?
              xml.source {
                xml.label 'Volume'
                xml.value rec['static_data']['summary']['pub_info']['vol']
              }
              xml.authors {
                xml.label 'Authors'
                Array.wrap(rec['static_data']['summary']['names']['name']).each do |name|
                  xml.value name['full_name']
                end
              } unless rec['static_data']['summary']['names'].nil?
              xml.keywords {
                xml.label 'Keywords'
                Array.wrap(rec['static_data']['fullrecord_metadata']['keywords']['keyword']).each do |keyword|
                  xml.value keyword
                end
              } unless rec['static_data']['fullrecord_metadata']['keywords'].nil?
              xml.other {
                xml.label 'Identifier.Doi'
                xml.value doi['value']
              } unless doi.nil?
              xml.other {
                xml.label 'Identifier.Eissn'
                xml.value eissn['value']
              } unless eissn.nil?
              xml.other {
                xml.label 'Identifier.Ids'
                xml.value rec['static_data']['item']['ids']['content']
              }
              xml.other {
                xml.label 'Identifier.Issn'
                xml.value issn['value']
              } unless issn.nil?
            }
          end
        }
      end
      WebOfScience::XmlParser.parse(builder.to_xml, nil)
    end

    # Group records by the database prefix in the UID
    #  - where a database prefix is missing, groups records into 'MISSING_DB'
    # @return [Hash<String => WebOfScience::Records>]
    def by_database
      db_recs = rec_nodes.group_by do |rec|
        uid_split = record_uid(rec).split(':')
        uid_split.length > 1 ? uid_split[0] : 'MISSING_DB'
      end
      db_recs.each_key do |db|
        rec_doc = Nokogiri::XML("<records>#{db_recs[db].map(&:to_xml).join}</records>")
        db_recs[db] = WebOfScience::Records.new(xml: rec_doc.to_xml)
      end
      db_recs
    end

    # Iterate over WebOfScience::WokRecord objects
    # @yield [WebOfScience::Record]
    def each
      rec_nodes.each { |rec| yield WebOfScience::Record.new(xml: rec.to_xml) }
    end

    # @return [Array<String>] the rec_nodes UID values (in order)
    def uids
      uid_nodes.map(&:text)
    end

    # @return [Nokogiri::XML::NodeSet] the rec_nodes UID nodes
    def uid_nodes
      rec_nodes.search('uid')
    end

    # Find duplicate WoS UID values
    # @param record_setB [WebOfScience::Records]
    # @return [Array] duplicate WoS UID values
    def duplicate_uids(record_setB)
      uids & record_setB.uids
    end

    # Find duplicate WoS records
    # @param record_setB [WebOfScience::Records]
    # @return [Nokogiri::XML::NodeSet] duplicate records
    def duplicate_records(record_setB)
      duplicates = []
      uid_intersection = duplicate_uids(record_setB)
      unless uid_intersection.empty?
        # create a new set of records, use a philosophy of immutability
        # Nokogiri::XML::NodeSet enumerable methods do not return new objects
        # Nokogiri::XML::Document.dup is a deep copy
        docB = record_setB.doc.dup # do not chain Nokogiri methods
        duplicates = docB.search('records').select { |rec| uid_intersection.include? record_uid(rec) }
        #duplicates = docB.search('REC').select { |rec| uid_intersection.include? record_uid(rec) }
      end
      Nokogiri::XML::NodeSet.new(Nokogiri::XML::Document.new, duplicates)
    end

    # Find new WoS records, rejecting duplicates
    # @param record_setB [WebOfScience::Records]
    # @return [Nokogiri::XML::NodeSet] additional new records
    def new_records(record_setB)
      # create a new set of records, use a philosophy of immutability
      # Nokogiri::XML::NodeSet enumerable methods do not return new objects
      # Nokogiri::XML::Document.dup is a deep copy
      docB = record_setB.doc.dup # do not chain Nokogiri methods
      new_rec = docB.search('records')
      #new_rec = docB.search('REC')
      # reject duplicate records
      uid_dups = duplicate_uids(record_setB)
      new_rec = new_rec.reject { |rec| uid_dups.include? record_uid(rec) } unless uid_dups.empty?
      Nokogiri::XML::NodeSet.new(Nokogiri::XML::Document.new, new_rec)
    end

    # Merge WoS records
    # @param record_setB [WebOfScience::Records]
    # @return [WebOfScience::Records] merged set of records
    def merge_records(record_setB)
      # create a new set of records, use a philosophy of immutability
      # Nokogiri::XML::Document.dup is a deep copy
      docA = doc.dup # do not chain Nokogiri methods
      # merge new records and return a new WebOfScience::Records instance
      docA.at('records').add_next_sibling(new_records(record_setB))
      WebOfScience::Records.new(xml: docA.to_xml)
    end

    # Pretty print the records in XML
    # @return [nil]
    def print
      require 'rexml/document'
      rexml_doc = REXML::Document.new(doc.to_xml)
      formatter = REXML::Formatters::Pretty.new
      formatter.compact = true
      formatter.write(rexml_doc, $stdout)
      nil
    end

    # Extract all the 'REC' nodes
    # @return [Nokogiri::XML::NodeSet]
    def rec_nodes
      doc.search('records')
    end

    private

      # The UID for a WoS REC
      # @param rec [Nokogiri::XML::Element] a Wos 'REC' element
      # @return [String] a Wos 'UID' value
      def record_uid(rec)
        rec.search('uid').text
      end

  end
end