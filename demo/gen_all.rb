load 'lib/nmspec.rb'

result =  Nmspec::V1.gen({
            'spec' => IO.read('demo/base_types.nmspec'),
            'langs' => ['ruby', 'gdscript']
          })

File.open('generated_code/base_types.rb', 'w'){|f| f.puts result.dig('code', 'ruby') }
File.open('generated_code/base_types.gd', 'w'){|f| f.puts result.dig('code', 'gdscript') }
