# Frontend 

Frontend static files of the resume site. 

## Tests

Cypress end-to-end tests can be found in [cypress/e2e](cypress/e2e/). Backend must be deployed to staging in order for the e2e tests to pass.

## Deployment

Prodction deployment requires a replacement of API endpoint string in [counter.js](src/counter.js). This is achieved by calling the helper script [build_dist.sh](build/build_dist.sh) from the [frontend deployment workflow](../.github/workflows/deploy-frontend.yml).

## Contributing

Feedback, suggestions and pull requests for are welcome. Please open an issue first to discuss what you would like to change.