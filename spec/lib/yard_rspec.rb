
class RSpecDescribeHandler < YARD::Handlers::Ruby::Base
  handles method_call(:describe)

  def process
    param = statement.parameters.first.jump(:string_content).source

    obj = owner || {}
    if param == 'Neo4j::Core::Query'
      obj = {spec: ''}
    elsif obj[:spec]
      case param[0]
      when '#'
        obj[:spec] = "Neo4j::Core::Query#{param}"
      when '.'
        obj[:ruby] = param
      end
    end

    parse_block(statement.last.last, owner: obj)
  rescue YARD::Handlers::NamespaceMissingError
  end
end

class RSpecItGeneratesHandler < YARD::Handlers::Ruby::Base
  handles method_call(:it_generates)

  def process
    return if owner.nil?

    return unless owner[:spec]
    path = owner[:spec]
    ruby = owner[:ruby]

    object = P(path)
    return if object.is_a?(Proxy)

    cypher = statement.parameters.first.jump(:string_content).source

    (object[:examples] ||= []) << {
      path: path,
      ruby: ruby,
      cypher: cypher
    }
  end
end

YARD::Templates::Engine.register_template_path File.dirname(__FILE__) + '/yard_rspec/templates'
