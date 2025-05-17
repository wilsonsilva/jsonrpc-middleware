class App
  def call(env)
    request = env['jason.request']

    result = case request.method
              when 'add'
                1 + 1
              when 'subtract'
                1 - 1
              when 'multiply'
                1 * 1
              when 'divide'
                1/1
             end

    [200, { 'content-type' => 'application/json' }, [result]]
  end
end
