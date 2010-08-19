# Patch Webrat
Webrat::Methods.module_eval do
  undef_method :response
end
