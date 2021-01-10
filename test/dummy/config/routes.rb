Rails.application.routes.draw do
  mount ConstraintValidations::Engine => "/constraint_validations"
end
