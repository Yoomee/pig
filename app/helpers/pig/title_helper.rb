module Pig::TitleHelper
  def title(text)
    @page_title ||= text
  end
end
