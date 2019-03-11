class ApiMaker::IndexCommandService < ApiMaker::CommandService
  def execute!
    ApiMaker::IndexCommand.execute_in_thread!(
      ability: ability,
      args: args,
      collection: collection,
      commands: commands,
      command_response: command_response,
      controller: controller
    )
  end

  def collection
    @collection ||= klass.accessible_by(@ability)
  end

  def ids
    @ids ||= @commands.values.map { |command| command.fetch("primary_key") }
  end

  def klass
    @klass ||= @model_name.singularize.camelize.constantize
  end
end
