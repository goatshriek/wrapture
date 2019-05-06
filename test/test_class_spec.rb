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


end
