# MVVM Documentation Generation Prompt

## Context
I need comprehensive technical documentation for my university project that implements MVVM architecture in both iOS and Android. This documentation will be used during an oral exam where I'll be asked to walk through specific scenarios and explain the code flow step-by-step.

## Your Task
Generate detailed, scenario-based documentation that traces code execution paths through the MVVM layers. The documentation should be structured to help me confidently explain any user interaction during my exam.

## Documentation Requirements

### 1. Project Overview Section
- Brief description of the application purpose
- List of main features/screens
- Technology stack for both platforms:
  - iOS: Language (Swift/SwiftUI), frameworks, reactive libraries (Combine/RxSwift)
  - Android: Language (Kotlin/Java), frameworks, reactive libraries (LiveData/Flow/RxJava)

### 2. MVVM Architecture Explanation
Provide a clear explanation of how MVVM is implemented in both platforms:
- **Model Layer**: Data structures, entities, network models, database models
- **View Layer**: UI components, screens, activities/fragments (Android), ViewControllers/Views (iOS)
- **ViewModel Layer**: Business logic, state management, data transformation
- **Data Flow**: How data moves between layers (unidirectional/bidirectional)
- **Dependency Injection**: How dependencies are provided (if applicable)

### 3. Scenario-Based Code Flow Documentation
For EACH major feature/screen, create a detailed scenario walkthrough:

#### Scenario Template:
```
### Scenario: [Feature Name - e.g., "User Login"]

**User Action**: [What the user does - e.g., "User enters credentials and taps Login button"]

**Platform**: iOS / Android / Both

**Code Flow**:

1. **VIEW LAYER**
   - File: `[FileName.swift/kt]`
   - Component: `[Specific UI element]`
   - Code snippet: `[Relevant code]`
   - What happens: [Explanation]
   - Next step: Triggers [method/event]

2. **VIEWMODEL LAYER**
   - File: `[ViewModelName.swift/kt]`
   - Method: `[methodName()]`
   - Code snippet: `[Relevant code]`
   - What happens: [Explanation]
   - Data transformations: [If any]
   - State changes: [What state updates occur]
   - Next step: Calls [service/repository]

3. **MODEL/REPOSITORY LAYER**
   - File: `[RepositoryName.swift/kt]`
   - Method: `[methodName()]`
   - Code snippet: `[Relevant code]`
   - What happens: [API call, database query, etc.]
   - Response handling: [Success/Error cases]

4. **RETURN PATH**
   - How data flows back through the layers
   - State updates in ViewModel
   - UI updates in View
   - Observable/binding mechanism used

**Key Points for Exam**:
- [Important concept 1]
- [Important concept 2]
- [Potential questions and answers]

**Error Handling**:
- What happens if [error scenario]
- How errors are propagated
- User feedback mechanism
```

### 4. Required Scenarios to Document
Please create detailed walkthroughs for these common scenarios:

1. **App Launch Flow**
   - Initial screen loading
   - Authentication check
   - Navigation to appropriate screen

2. **Data Loading Scenario**
   - List/collection loading (e.g., loading a list of items)
   - Pagination (if applicable)
   - Pull-to-refresh

3. **User Input & Form Submission**
   - Form validation
   - Data submission
   - Success/error handling

4. **Navigation Flow**
   - Screen-to-screen navigation
   - Data passing between screens
   - Back navigation handling

5. **State Management**
   - Loading states
   - Error states
   - Empty states
   - Success states

6. **Data Persistence**
   - Saving data locally
   - Retrieving cached data
   - Sync mechanisms

### 5. Class Diagrams and Relationships
- Diagram showing relationships between View-ViewModel-Model
- Dependency graph
- Data flow arrows

### 6. Code Snippets Reference
For each major class, provide:
- Class signature
- Key properties
- Key methods with brief explanations
- Observable/binding properties

### 7. Platform-Specific Considerations
Document differences between iOS and Android implementations:
- Data binding mechanisms (SwiftUI @Published vs LiveData/StateFlow)
- Navigation patterns
- Lifecycle handling
- Memory management considerations

### 8. Common Exam Questions & Answers
Prepare answers for:
- "Why did you choose MVVM?"
- "How does data binding work in your implementation?"
- "What happens when [specific user action]?"
- "How do you handle [error scenario]?"
- "Explain the lifecycle of [ViewModel/View]"
- "How would you test this component?"

### 9. Testing Strategy
- How ViewModels can be unit tested
- Mock dependencies
- Test scenarios for each feature

## Output Format
- Use clear headers and subheaders
- Include actual code snippets from the project
- Use diagrams where helpful (describe them if you can't draw)
- Include file paths and line numbers for easy reference
- Highlight critical concepts in **bold**
- Use numbered steps for sequential flows
- Add notes/tips for explaining during the exam

## Additional Instructions
- Make it verbose and detailed - I need to understand every step
- Use simple language for complex concepts
- Include "what to say during exam" tips
- Anticipate follow-up questions the examiner might ask
- Include timing estimates (e.g., "This operation takes ~2 seconds")
- Note any design patterns used (Observer, Repository, Factory, etc.)

## Project-Specific Information to Include
[PASTE YOUR PROJECT DETAILS HERE:]
- Repository URL or project structure
- Key features list
- Specific screens/modules you want documented
- Any particular scenarios you're concerned about
- Code samples from critical sections

---

Please generate comprehensive documentation following this structure that will help me confidently walk through any scenario during my oral exam.