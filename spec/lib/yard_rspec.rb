
class RSpecDescribeHandler < YARD::Handlers::Ruby::Base
  handles method_call(:describe)

  def process
    param = statement.parameters.first.jump(:string_content).source

    parse_block(statement.last.last, owner: obj_for_param(param))
  rescue YARD::Handlers::NamespaceMissingError
  end

  private

  def obj_for_param(param)
    (owner || {}).tap do |obj|
      if param == 'Neo4j::Core::Query'
        obj = {spec: ''}
      elsif obj[:spec]
        case param[0]
        when '#' then obj[:spec] = "Neo4j::Core::Query#{param}"
        when '.' then obj[:ruby] = param
        end
      end
    end
  end
end

class RSpecItGeneratesHandler < YARD::Handlers::Ruby::Base
  handles method_call(:it_generates)

  def process
    return if owner.nil?

    return unless owner[:spec]
    path, ruby = [owner[:spec], owner[:ruby]]

    object = P(path)
    return if object.is_a?(Proxy)

    cypher = statement.parameters.first.jump(:string_content).source

    (object[:examples] ||= []) << {path: path, ruby: ruby, cypher: cypher}
  end
end

YARD::Templates::Engine.register_template_path File.dirname(__FILE__) + '/yard_rspec/templates'
