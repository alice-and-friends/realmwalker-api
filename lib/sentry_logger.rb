# frozen_string_literal: true

if defined? Logger
  class SentryLogger < Logger
    def error(progname = nil, &block)
      super
      Sentry.capture_message(progname, level: :error) if progname
    end
  end
end
