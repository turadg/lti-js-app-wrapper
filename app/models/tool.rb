class Tool < ActiveRecord::Base
  validates :title, presence: true
  validates :body, presence: true

  rails_admin do
  	field :title do
	  html_attributes size: 40
	end
  	field :description do
	  html_attributes size: 60
	end
	field :body, :wysihtml5 do
	  config_options toolbar: { fa: true } # use font-awesome instead of glyphicon
	end
  end

end
