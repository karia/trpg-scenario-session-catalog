module ManageHelper
  def manage_nav_class(path)
    current = request.path.start_with?(path)
    "no-underline #{current ? 'text-ink font-bold' : 'text-seal'}"
  end
end
