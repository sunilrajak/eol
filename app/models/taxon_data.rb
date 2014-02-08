#encoding: utf-8
class TaxonData < TaxonUserClassificationFilter

  include EOL::Sparql::SafeConnection
  extend EOL::Sparql::SafeConnection

  DEFAULT_PAGE_SIZE = 30
  MAXIMUM_DESCENDANTS_FOR_CLADE_RANGES = 15000
  MAXIMUM_DESCENDANTS_FOR_CLADE_SEARCH = 60000

  # TODO - this doesn't belong here; it has nothing to do with a taxon concept. Move to a DataSearch class. Fix the
  # controller.
  def self.search(options={})
    if_connection_fails_return(nil) do
      # only attribute is required, querystring may be left blank to get all usages of an attribute
      return [].paginate if options[:attribute].blank? # TODO - remove this when we allow other searches!
      options[:page] ||= 1
      options[:per_page] ||= TaxonData::DEFAULT_PAGE_SIZE
      options[:language] ||= Language.default
      total_results = EOL::Sparql.connection.query(EOL::Sparql::SearchQueryBuilder.prepare_search_query(options.merge(only_count: true))).first[:count].to_i
      results = EOL::Sparql.connection.query(EOL::Sparql::SearchQueryBuilder.prepare_search_query(options))
      if options[:for_download]
        # when downloading, we don't the full TaxonDataSet which will want to insert rows into MySQL
        # for each DataPointUri, which is very expensive when downloading lots of rows
        KnownUri.add_to_data(results)
        data_point_uris = results.collect do |row|
          data_point_uri = DataPointUri.new(DataPointUri.attributes_from_virtuoso_response(row))
          data_point_uri.convert_units
          data_point_uri
        end
        DataPointUri.preload_associations(data_point_uris, { taxon_concept:
            [ { preferred_entry: { hierarchy_entry: { name: :ranked_canonical_form } } } ],
            resource: :content_partner },
          select: {
            taxon_concepts: [ :id ],
            hierarchy_entries: [ :id, :taxon_concept_id, :name_id ],
            names: [ :id, :string, :ranked_canonical_form_id ],
            canonical_forms: [ :id, :string ] }
          )
      else
        taxon_data_set = TaxonDataSet.new(results)
        data_point_uris = taxon_data_set.data_point_uris
        DataPointUri.preload_associations(data_point_uris, :taxon_concept)
        # This next line is for catching a rare case, seen in development, when the concept
        # referred to by Virtuoso is not in the database
        data_point_uris.delete_if{ |dp| dp.taxon_concept.nil? }
        TaxonConcept.preload_for_shared_summary(data_point_uris.collect(&:taxon_concept), language_id: options[:language].id)
      end
      TaxonConcept.load_common_names_in_bulk(data_point_uris.collect(&:taxon_concept), options[:language].id)
      WillPaginate::Collection.create(options[:page], options[:per_page], total_results) do |pager|
         pager.replace(data_point_uris)
      end
    end
  end

  def self.is_clade_searchable?(taxon_concept)
    taxon_concept.number_of_descendants <= TaxonData::MAXIMUM_DESCENDANTS_FOR_CLADE_SEARCH
  end

  def downloadable?
    ! bad_connection? && ! get_data.blank? 
  end

  def topics
    if_connection_fails_return([]) do
      @topics ||= get_data.map { |d| d[:attribute] }.select { |a| a.is_a?(KnownUri) }.uniq.compact.map(&:name)
    end
  end

  def categories
    if_connection_fails_return([]) do
      get_data unless @categories
      @categories
    end
  end

  # NOTE - nil implies bad connection. You should get a TaxonDataSet otherwise!
  def get_data
    if_connection_fails_return(nil) do
      return @taxon_data_set.dup if @taxon_data_set
      taxon_data_set = TaxonDataSet.new(raw_data, taxon_concept_id: taxon_concept.id, language: user.language)
      taxon_data_set.sort
      known_uris = taxon_data_set.collect{ |data_point_uri| data_point_uri.predicate_known_uri }.compact
      KnownUri.preload_associations(known_uris,
                                    [ { toc_items: :translations },
                                      { known_uri_relationships_as_subject: :to_known_uri },
                                      { known_uri_relationships_as_target: :from_known_uri } ] )
      @categories = known_uris.flat_map(&:toc_items).uniq.compact
      @taxon_data_set = taxon_data_set
      raise EOL::Exceptions::SparqlDataEmpty if taxon_data_set.nil?
      @taxon_data_set
    end
  end

  # NOTE - nil implies bad connection. Empty set ( [] ) implies nothing to show.
  def get_data_for_overview
    picker = TaxonDataExemplarPicker.new(self).pick
  end

  def distinct_predicates
    data = get_data
    unless data.nil? || ranges_of_values.nil?
      ( data.collect{ |d| d.predicate }.compact + 
        ranges_of_values.collect{ |r| r[:attribute] } ).uniq
    else
      return []
    end
  end

  def has_range_data
    ! ranges_of_values.empty?
  end

  def ranges_of_values
    return [] unless should_show_clade_range_data
    EOL::Sparql::Client.if_connection_fails_return({}) do
    results = EOL::Sparql.connection.query(prepare_range_query).delete_if{ |r| r[:measurementOfTaxon] != Rails.configuration.uri_true}
      KnownUri.add_to_data(results)
      results.each do |result|
        [ :min, :max ].each do |m|
          result[m] = result[m].value.to_f if result[m].is_a?(RDF::Literal)
          result[m] = DataPointUri.new(DataPointUri.attributes_from_virtuoso_response(result).merge(object: result[m]))
          result[m].convert_units
        end
      end
      results.delete_if{ |r| r[:min].object.blank? || r[:max].object.blank? || (r[:min].object == 0 && r[:max].object == 0) }
    end
  end

  def ranges_for_overview
    ranges_of_values.select{ |range| KnownUri.uris_for_clade_exemplars.include?(range[:attribute].uri) }
  end

  def rating_for_guid(guid)
    @ratings ||= user.rating_for_object_guids(guids)
    @ratings[guid]
  end

  private

    def raw_data
      (measurement_data + association_data).delete_if { |k,v| k[:attribute].blank? }
    end

    def measurement_data(options = {})
      selects = "?attribute ?value ?unit_of_measure_uri ?statistical_method ?life_stage ?sex ?data_point_uri ?graph ?taxon_concept_id"
      query = "
        SELECT DISTINCT #{selects}
        WHERE {
          GRAPH ?graph {
            ?data_point_uri dwc:measurementType ?attribute .
            ?data_point_uri dwc:measurementValue ?value .
            OPTIONAL { ?data_point_uri dwc:measurementUnit ?unit_of_measure_uri } .
            OPTIONAL { ?data_point_uri eolterms:statisticalMethod ?statistical_method } .
          } .
          {
            ?data_point_uri dwc:taxonConceptID ?taxon_concept_id .
            FILTER( ?taxon_concept_id = <#{UserAddedData::SUBJECT_PREFIX}#{taxon_concept.id}>)
            OPTIONAL { ?data_point_uri dwc:lifeStage ?life_stage } .
            OPTIONAL { ?data_point_uri dwc:sex ?sex }
          }
          UNION {
            ?data_point_uri dwc:occurrenceID ?occurrence .
            ?occurrence dwc:taxonID ?taxon .
            ?data_point_uri eol:measurementOfTaxon eolterms:true .
            GRAPH ?resource_mappings_graph {
              ?taxon dwc:taxonConceptID ?taxon_concept_id .
              FILTER( ?taxon_concept_id = <#{UserAddedData::SUBJECT_PREFIX}#{taxon_concept.id}>)
            }
            OPTIONAL { ?occurrence dwc:lifeStage ?life_stage } .
            OPTIONAL { ?occurrence dwc:sex ?sex }
          }
        }
        LIMIT 800"
      EOL::Sparql.connection.query(query)
    end

    def association_data(options = {})
      selects = "?attribute ?value ?target_taxon_concept_id ?inverse_attribute ?data_point_uri ?graph"
      query = "
        SELECT DISTINCT #{selects}
        WHERE {
          GRAPH ?resource_mappings_graph {
            ?taxon dwc:taxonConceptID ?source_taxon_concept_id .
            FILTER(?source_taxon_concept_id = <#{UserAddedData::SUBJECT_PREFIX}#{taxon_concept.id}>) .
            ?value dwc:taxonConceptID ?target_taxon_concept_id
          } .
          GRAPH ?graph {
            ?occurrence dwc:taxonID ?taxon .
            ?target_occurrence dwc:taxonID ?value .
            {
              ?data_point_uri dwc:occurrenceID ?occurrence .
              ?data_point_uri eol:targetOccurrenceID ?target_occurrence .
              ?data_point_uri eol:associationType ?attribute
            }
            UNION
            {
              ?data_point_uri dwc:occurrenceID ?target_occurrence .
              ?data_point_uri eol:targetOccurrenceID ?occurrence .
              ?data_point_uri eol:associationType ?inverse_attribute
            }
          } .
          OPTIONAL {
            GRAPH ?mappings {
              ?inverse_attribute owl:inverseOf ?attribute
            }
          }
        }
        LIMIT 800"
      EOL::Sparql.connection.query(query)
    end

    def prepare_range_query(options = {})
      query = "
        SELECT ?attribute, ?measurementOfTaxon, COUNT(DISTINCT ?descendant_concept_id) as ?count_taxa,
          COUNT(DISTINCT ?data_point_uri) as ?count_measurements,
          MIN(xsd:float(?value)) as ?min, MAX(xsd:float(?value)) as ?max, ?unit_of_measure_uri
        WHERE {
          ?parent_taxon dwc:taxonConceptID <#{UserAddedData::SUBJECT_PREFIX}#{taxon_concept.id}> .
          ?t dwc:parentNameUsageID+ ?parent_taxon .
          ?t dwc:taxonConceptID ?descendant_concept_id .
          ?occurrence dwc:taxonID ?taxon .
          ?taxon dwc:taxonConceptID ?descendant_concept_id .
          ?data_point_uri dwc:occurrenceID ?occurrence .
          ?data_point_uri eol:measurementOfTaxon ?measurementOfTaxon .
          ?data_point_uri dwc:measurementType ?attribute .
          ?data_point_uri dwc:measurementValue ?value .
          OPTIONAL {
            ?data_point_uri dwc:measurementUnit ?unit_of_measure_uri
          }
          FILTER ( ?attribute IN (IRI(<#{KnownUri.uris_for_clade_aggregation.join(">),IRI(<")}>)))
        }
        GROUP BY ?attribute ?unit_of_measure_uri ?measurementOfTaxon
        ORDER BY DESC(?min)"
      query
    end

end
