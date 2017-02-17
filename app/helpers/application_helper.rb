module ApplicationHelper
  def nav_link(label, path, active)
    content_tag(:li, class: ('active' if active)) do
      link_to label, path
    end
  end
end
