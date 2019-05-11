require 'minitest/autorun'
require 'wrapture'

class ClassSpecTest < Minitest::Test
  def test_normalize
    test_spec = {
      'name' => 'TestClass',
      'equivalent-struct' => {
        'name' => 'test_struct'
      }
    }

    normalized_spec = Wrapture::ClassSpec.normalize_spec_hash test_spec

    assert normalized_spec != nil
  end

  def test_generate_wrappers
    test_spec = {
      'name' => "TestClass",
      'equivalent-struct' => {
        'name' => 'test_struct',
        'includes' => ['folder/include_file_1.h']
      },
      'functions' => [{
        'name' => 'TestFunction1',
        'params' => [{'name'=>'app_name','type'=>'const char *'}],
        'wrapped-function' => {
          'name' => 'test_native_function',
          'includes' => ['folder/include_file_2.h'],
          'params' => [
            {'name' => 'equivalent-struct-pointer'},
            {'name' => 'app_name'}
          ]
        }
      }]
    }

    spec = Wrapture::ClassSpec.new test_spec

    spec.generate_wrappers
  end
end
