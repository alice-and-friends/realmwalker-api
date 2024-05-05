# frozen_string_literal: true

class NaturalLanguageHelper
  FILTER_HATE = LanguageFilter::Filter.new matchlist: :hate, creative_letters: true
  FILTER_PROFANITY = LanguageFilter::Filter.new matchlist: :profanity, creative_letters: true
  FILTER_SEX = LanguageFilter::Filter.new matchlist: :sex, creative_letters: true
  FILTER_VIOLENCE = LanguageFilter::Filter.new matchlist: :violence, creative_letters: true
  FILTER_CUSTOM = LanguageFilter::Filter.new matchlist: %w[nigger retard murder kys hate idiot], creative_letters: true

  def self.contains_offensive_language(text)
    normalized_text = normalize_text(text)
    FILTER_HATE.match?(normalized_text) || FILTER_PROFANITY.match?(normalized_text) ||
      FILTER_SEX.match?(normalized_text) || FILTER_VIOLENCE.match?(normalized_text) || FILTER_CUSTOM.match?(normalized_text)
  end

  # Normalize the text by translating leetspeak and removing non-alphabetical characters
  def self.normalize_text(text)
    text = text.gsub(/[4@]/, 'a')
               .gsub(/8/, 'b')
               .gsub(/\(/, 'c')
               .gsub(/[3]/, 'e')
               .gsub(/[6]/, 'g')
               .gsub(/[#]/, 'h')
               .gsub(/[1!|]/, 'i')
               .gsub(/[0]/, 'o')
               .gsub(/[5$]/, 's')
               .gsub(/[7+]/, 't')
               .gsub(/2/, 'z')
               .gsub(/[_]/, ' ') # Remove underscores and other non-word characters
    text.downcase
  end
end
