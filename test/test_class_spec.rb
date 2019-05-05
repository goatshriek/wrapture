require 'minitest/autorun'
require 'wrapture'

class ClassSpecTest < Minitest::Test
  def test_normalize
    test_spec = {}

    normalized_spec = Wrapture::ClassSpec.normalize_spec_hash test_spec

    normalized_spec.wont_be_nil
  end


end
