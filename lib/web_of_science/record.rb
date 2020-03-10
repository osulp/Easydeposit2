require 'forwardable'

module WebOfScience

  # Utilities for working with a Web of Knowledge (WOK) record
  class Record
    extend Forwardable

    delegate logger: :WebOfScience

    # @!attribute [r] doc
    # @return [Nokogiri::XML::Document] WOS record document
    attr_reader :doc

    # @param record [String] record in XML
    # @param encoded_record [String] record in HTML encoding
    def initialize(xml: nil, json: nil)
      raise(ArgumentError, 'xml and json cannot both be nil') if xml.nil? && json.nil?
      raise(ArgumentError, 'Only one of xml or json may be used to construct a WOS Record') unless xml.nil? || json.nil?
      @doc = WebOfScience::XmlParser.parse(xml, nil) unless (xml.nil?)
      @doc = json_to_xml(json) unless (json.nil?)
    end

    def json_to_xml(json)
      atitle = json['static_data']['summary']['titles']['title'].select { |title| title['type'] == 'item' }.first['content']
      jtitle = json['static_data']['summary']['titles']['title'].select { |title| title['type'] == 'source' }.first['content']
      doi = json['dynamic_data']['cluster_related']['identifiers']['identifier'].select { |identifier| identifier['type'] == 'doi' }.first['value']
      issn = json['dynamic_data']['cluster_related']['identifiers']['identifier'].select { |identifier| identifier['type'] == 'issn' }.first['value']
      eissn = json['dynamic_data']['cluster_related']['identifiers']['identifier'].select { |identifier| identifier['type'] == 'eissn' }.first['value']

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.records {
          xml.uid json['UID']
          xml.title {
            xml.label 'title'
            xml.value atitle
          }
          xml.doctype {
            xml.label 'Doctype'
            xml.value json['static_data']['summary']['doctypes']['doctype']
          }
          xml.source {
            xml.label 'Issue'
            xml.value json['static_data']['summary']['pub_info']['issue']
          }
          xml.source {
            xml.label 'Pages'
            xml.value json['static_data']['summary']['pub_info']['page']['content']
          }
          xml.source {
            xml.label 'Published.BiblioDate'
            xml.value json['static_data']['summary']['pub_info']['pubmonth']
          }
          xml.source {
            xml.label 'Published.BiblioYear'
            xml.value json['static_data']['summary']['pub_info']['pubyear']
          }
          xml.source {
            xml.label 'SourceTitle'
            xml.value jtitle
          }
          xml.source {
            xml.label 'Volume'
            xml.value json['static_data']['summary']['pub_info']['vol']
          }
          xml.authors {
            xml.label 'Authors'
            json['static_data']['summary']['names']['name'].each do |name|
              xml.value name['full_name']
            end
          }
          xml.keywords {
            xml.label 'Keywords'
            json['static_data']['fullrecord_metadata']['keywords']['keyword'].each do |keyword|
              xml.value keyword
            end
          }
          xml.other {
            xml.label 'Identifier.Doi'
            xml.value doi
          }
          xml.other {
            xml.label 'Identifier.Eissn'
            xml.value eissn
          }
          xml.other {
            xml.label 'Identifier.Ids'
            xml.value json['static_data']['item']['ids']['content']
          }
          xml.other {
            xml.label 'Identifier.Issn'
            xml.value issn
          }
        }
        WebOfScience::XmlParser.parse(xml.to_xml)
      end
    end

    def uid
      doc.search('uid').text
    end

    def database
      @database ||= begin
        uid_split = uid.split(':')
        uid_split.length > 1 ? uid_split[0] : nil
      end
    end

    ['pages',
     'published.bibliodate',
     'published.biblioyear',
     'sourcetitle',
     'volume'].each do |key|
      define_method key.tr('.', '_').to_sym do
        nodes = doc.search('source').select do |node|
          node.children.any? { |n| n.text.casecmp(key).zero? }
        end
        nodes.map { |children| children.search('value').text }
      end
    end

    %w[authors keywords doctype title].each do |key|
      define_method key.to_sym do
        doc.search("#{key}/value").map(&:text)
      end
    end

    ['identifier.doi',
     'identifier.issn',
     'identifier.isbn',
     'contributor.researcherid.names',
     'contributor.researcherid.researcherids'].each do |key|
      define_method key.tr('.', '_').to_sym do
        nodes = doc.search('other').select do |node|
          node.children.any? { |n| n.text.casecmp(key).zero? }
        end
        nodes.map { |children| children.search('value').text }
      end
    end

    # Pretty print the record in XML
    # @return [nil]
    def print
      require 'rexml/document'
      rexml_doc = REXML::Document.new(doc.to_xml)
      formatter = REXML::Formatters::Pretty.new
      formatter.compact = true
      formatter.write(rexml_doc, $stdout)
      $stdout.write("\n")
      nil
    end

    # @return [Hash]
    def pub_hash
      @pub_hash ||= to_h
    end

    # Extract the REC fields
    # @return [Hash<String => Object>]
    def to_h
      {
        'authors' => authors,
        'biblio_dates' => published_bibliodate,
        'biblio_years' => published_biblioyear,
        'doctypes' => doctype,
        'dois' => identifier_doi,
        'isbns' => identifier_isbn,
        'issns' => identifier_issn,
        'keywords' => keywords,
        'pages' => pages,
        'researcher_ids' => contributor_researcherid_researcherids,
        'researcher_names' => contributor_researcherid_names,
        'source_titles' => sourcetitle,
        'titles' => title,
        'volumes' => volume
      }
    end

    # An OpenStruct for the REC fields
    # @return [OpenStruct]
    def to_struct
      # Convert Hash to OpenStruct with recursive application to nested hashes
      JSON.parse(to_h.to_json, object_class: OpenStruct)
    end

    # @return [String] XML
    def to_xml
      doc.to_xml(save_with: WebOfScience::XmlParser::XML_OPTIONS).strip
    end
  end
end
