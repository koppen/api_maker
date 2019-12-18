class ApiMaker::CreateCommand < ApiMaker::BaseCommand
  attr_reader :command, :model, :params, :serializer

  def execute!
    each_command do |command|
      @command = command
      @model = collection.klass.new
      @params = command.args || {}
      @serializer = serialized_resource(model)
      sanitized_parameters = sanitize_parameters
      @model.assign_attributes(sanitized_parameters)

      if !current_ability.can?(:create, @model)
        failure_response(errors: ["No access to create that resource"])
      elsif @model.save
        success_response
      else
        failure_save_response(model: model, params: sanitized_parameters)
      end
    end

    ServicePattern::Response.new(success: true)
  end

  def api_maker_resource_class
    @api_maker_resource_class ||= "Resources::#{collection.klass.name}Resource".constantize
  end

  def resource_instance_class_name
    @resource_instance_class_name ||= self.class.name.split("::").last.gsub(/Controller$/, "").singularize
  end

  def resource_instance_class
    @resource_instance_class ||= api_maker_resource_class.model_class
  end

  def resource_variable_name
    @resource_variable_name ||= resource_instance_class_name.underscore.parameterize
  end

  def sanitize_parameters
    serializer.resource_instance.permitted_params(ApiMaker::PermittedParamsArgument.new(command: command, model: model))
  end

  def serialized_resource(model)
    ApiMaker::Serializer.new(ability: current_ability, args: api_maker_args, model: model)
  end

  def success_response
    command.result(
      model: serializer.result,
      success: true
    )
  end
end
