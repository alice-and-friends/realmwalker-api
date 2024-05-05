# frozen_string_literal: true

require 'test_helper'

class NaturalLanguageHelperTest < ActiveSupport::TestCase
  test 'should allow phrases' do
    assert_not NaturalLanguageHelper.contains_offensive_language 'Hello'
    assert_not NaturalLanguageHelper.contains_offensive_language 'Nice'
    assert_not NaturalLanguageHelper.contains_offensive_language 'Alice'
    assert_not NaturalLanguageHelper.contains_offensive_language 'Alice Middlename Lastname'
    assert_not NaturalLanguageHelper.contains_offensive_language 'Scunthorpe'
    assert_not NaturalLanguageHelper.contains_offensive_language 'Lover'
  end

  test 'should disallow phrases' do
    assert NaturalLanguageHelper.contains_offensive_language 'cunt'
    assert NaturalLanguageHelper.contains_offensive_language 'A$$'
    assert NaturalLanguageHelper.contains_offensive_language 'nigger'
    assert NaturalLanguageHelper.contains_offensive_language 'Fuck'
    assert NaturalLanguageHelper.contains_offensive_language 'ret4rd'
    assert NaturalLanguageHelper.contains_offensive_language 'murder'
    assert NaturalLanguageHelper.contains_offensive_language 'hate you'
    assert NaturalLanguageHelper.contains_offensive_language 'kys'
    assert NaturalLanguageHelper.contains_offensive_language 'idiot'
    assert NaturalLanguageHelper.contains_offensive_language 'fag'
  end

  test 'should handle mixed cases and obfuscations' do
    assert NaturalLanguageHelper.contains_offensive_language 'fuCk'
    assert NaturalLanguageHelper.contains_offensive_language 'N1gg3r'
    assert NaturalLanguageHelper.contains_offensive_language 's3x'
    assert NaturalLanguageHelper.contains_offensive_language 'k1ll'
    assert NaturalLanguageHelper.contains_offensive_language '4$$_m4$t3r'
  end

  test 'should sanitize text' do
    offensive_text = 'suck this dick, r3tard'
    assert NaturalLanguageHelper.contains_offensive_language offensive_text
    sanitized_text = NaturalLanguageHelper.sanitize offensive_text
    assert_not NaturalLanguageHelper.contains_offensive_language sanitized_text
  end
end
