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

    refute_nil normalized_spec
  end

  def test_generate_wrappers
    class_name = 'TestClass'

    test_spec = {
      'name' => class_name,
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

    classes = spec.generate_wrappers

    refute_nil classes
    refute_empty classes
    assert classes.length == 2
    assert classes.include? "#{class_name}.cpp"
    assert classes.include? "#{class_name}.hpp"

    File.delete(*classes)
  end
end
