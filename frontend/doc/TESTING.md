Running tests
====================



OpenProject is a hybrid application with most parts being Rails, along with some directives being used within Rails templates (the legacy application), and an Angular frontend for isolated SPA-like Modules such as the Work Packages module.



## Frontend specs



The Angular frontend services and components can be tested with frontend specs.


If you want to test services that have no dependencies, a simple instantiation of that class is sufficient to test the service in isolation. A good example is `  frontend/src/app/components/projects/current-project.service.spec.ts` 