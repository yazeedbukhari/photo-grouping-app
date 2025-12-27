# Project Logs

## Structure: YYYY-MM-DD
- what I did
- Next: what I'll do next
- Thoughts: questions or concepts I want to look into

## 2025-10-30
- set up image standardization (image resizing, normalizing etc) to feed into the ML model
- set up unit tests for those as well
- Next: start EmbeddingService; choose appropriate ML model and the hyperparams
- Thoughts: I should have a function that rates an images quality; it would be quite useful for SuggestionService

## 2025-10-31
- added an image quality extraction feature. subject to change when I start working on SuggestionService
- add embedding service using Apples FeaturePrint; made it modular in case I want to switch to 
- Next: clean up EmbeddingService code
- Thoughts: How do I add logging? where would it be written

## 2025-12-27
- restarting and finishing this project over winter break
- set up grouping service to group using dot similarity (vectors are already normalized during embedding generation)
- wrote it myself this time with chatgpt for syntax help
- Next: make the groups visible on the UI
- Thoughts: How does the UI connection work in Swift? I saw smth about MVVM model. I've done angular front-end that calls on backend. Maybe M is the backend, VM is the typesript code (kind of in a state), V is the html/css code?
