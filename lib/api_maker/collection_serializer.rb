class ApiMaker::CollectionSerializer
  attr_reader :ability, :args, :collection, :preload_param, :model_class, :select, :select_columns

  def initialize(ability: nil, args: {}, collection:, model_class: nil, query_params: nil)
    raise "No collection was given" unless collection

    query_params ||= {}
    select = ApiMaker::SelectParser.execute!(select: query_params[:select]) if query_params[:select]

    @ability = ability || ApiMaker::Ability.new(args: args)
    @args = args
    @collection = collection
    @preload_param = query_params[:preload]
    @model_class = model_class
    @select = select
    @select_columns = query_params[:select_columns]
  end

  def result
    @result ||= begin
      data = {
        data: {},
        preloaded: {}
      }

      records = {}
      parsed_collection.map do |model|
        add_model_to_records(model, data, records)
      end

      preload_collection(data, records) if parsed_collection.length.positive?
      data
    end
  end

  def add_model_to_records(model, data, records)
    serializer = serializer_for_model(model)
    resource = serializer.resource
    collection_name = resource.collection_name
    records[collection_name] ||= {}

    if model.new_record?
      id = "new-#{records.fetch(collection_name).length}"
    else
      id = ApiMaker::PrimaryIdForModel.get(model)
    end

    data.fetch(:preloaded)[collection_name] ||= {}
    data.fetch(:preloaded)[collection_name][id] ||= serializer

    data.fetch(:data)[collection_name] ||= []
    data.fetch(:data)[collection_name] << id

    records[collection_name][id] ||= serializer
  end

  def as_json(options = nil)
    result.as_json(options)
  end

  def parsed_collection
    @parsed_collection ||= begin
      new_collection = ApiMaker::SelectColumnsOnCollection.execute!(collection: collection, model_class: model_class, select_columns: select_columns)
      new_collection = new_collection.fix unless new_collection.is_a?(Array)
      new_collection
    end
  end

  def preload_collection(data, records)
    preloader = ApiMaker::Preloader.new(
      ability: ability,
      args: args,
      collection: parsed_collection,
      data: data,
      preload_param: preload_param,
      model_class: model_class,
      records: records,
      select: select,
      select_columns: select_columns
    )
    preloader.fill_data
  end

  def select_for(model)
    select&.dig(model.class)
  end

  def serializer_for_model(model)
    ApiMaker::Serializer.new(ability: ability, args: args, model: model, select: select_for(model))
  end

  def to_json(options = nil)
    JSON.generate(as_json(options))
  end
end
