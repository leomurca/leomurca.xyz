---
title: "Demystifying ViewModel Testing: Strategies for Crafting Test-Friendly ViewModels"
date: 2024-03-25T10:54:21-03:00
featured_image: "/img/demystifying-viewmodel-testing/featured_image.webp"
draft: false
---

![A green parrot](/img/demystifying-viewmodel-testing/cover-image-1.webp)

## Introduction

Have you ever been struggling when writing unit tests for your ViewModel? Difficulty
when writing tests is a BIG symptom that your ViewModel is poorly written. If the mere
thought of testing your ViewModel sends shivers down your spine or if you find yourself
wrestling with intricate setups just to verify a simple behavior, fear not – you're not
alone. Writing test-friendly ViewModels is a common challenge faced by many
developers, but the good news is that it's a challenge that can be conquered.

In this blog post, we'll explore the reasons behind the testing struggle, unraveling the
intricacies of ViewModel design that lead to testing headaches. More importantly, we'll
equip you with practical insights and techniques to transform your ViewModels into
test-friendly units, making the process of unit testing a seamless and efficient
experience. Let's embark on a journey to banish testing woes and elevate your
ViewModel game!

## What's a ViewModel?

First thing first, we need to define what a ViewModel is and what its existence purpose is. 
According to the [ViewModel overview](https://developer.android.com/topic/libraries/architecture/viewmodel): 
*"[...] the ViewModel class is a business logic or screen level state holder.".* In other words, 
it encapsulates related business logic and it exposes the Screen UI State.

However, any plain Kotlin class can be used as a StateHolder to encapsulate business
logic and expose some Screen UI State. So why do we need ViewModels?

The main reason that we use a ViewModel instead of a plain Kotlin class is that
ViewModels:
- Survives configuration changes (lifecycle-aware). These configuration changes
are related to a data persistence benefit from using ViewModels.
- Has great Jetpack integration and other libraries;
- Caches states.

Well, knowing the definition of a ViewModel and the reasons why we should use it, we
must implement and maintain it very carefully. And in case your ViewModel already
exists, pay attention to the symptoms that may indicate that it needs some care.

## Symptoms that indicate your ViewModel needs some care


### 1. Heavy logic
Having complex business logic or extensive data manipulation directly in the
ViewModel can be a great indicator that your ViewModel needs some attention.
This symptom will cause you lots of headaches testing and maintaining it. Notice
the `UserProfileViewModel` below, for example:

```kotlin
class UserProfileViewModel(
  private val userRepository: UserRepository,
  private val userLocalDataSource: UserLocalDataSource
) : ViewModel() {

  private val _userProfileState = MutableStateFlow<UserProfile?>(null)
  val userProfileState: StateFlow<UserProfile?> get() = _userProfileState

  private val _loadingState = MutableStateFlow<Boolean>(false)
  val loadingState: StateFlow<Boolean> get() = _loadingState

  init {
    // Initial loading of user profile
    loadUserProfile()
  }

  private fun loadUserProfile() {
    viewModelScope.launch(Dispatchers.IO) {
      try {
        _loadingState.emit(true)
        // Fetching user details from a remote server
        val remoteUserDetails = userRepository.fetchUserDetails()
        // Processing and transforming user details
        val processedUserProfile = processUserProfile(remoteUserDetails)
        // Updating the local database with the processed data
        userLocalDataSource.updateUserProfile(processedUserProfile)
        _userProfileState.emit(processedUserProfile)
      } catch (e: Exception) {
        // Handle errors and update UI accordingly
      } finally {
        _loadingState.emit(false)
      }
    }
  }

  private suspend fun processUserProfile(userDetails: UserDetails): UserProfile {
    // Heavy processing and transformation of user details
    // ...
    return UserProfile(/* Processed user profile data */)
  }
}
```

### 2. Large ViewModels
A large class is a well-known code smell for classes that have too many
responsibilities. That's not different for ViewModels. ViewModel's only
responsibility is to manage the data for the UI. Having overly large ViewModels
with too many responsibilities can make code hard to understand, test, and
maintain. Be mindful that following the SRP is fundamental for ViewModels too.
See the example below with too many responsibilities for a single ViewModel:


```kotlin
class LargeViewModel(
  private val userRepository: UserRepository,
  private val taskRepository: TaskRepository,
  private val analyticsManager: AnalyticsManager,
  // ... other dependencies ...
) : ViewModel() {
  // Properties for various data streams
  private val _userProfileState = MutableStateFlow<UserProfile?>(null)

  val userProfileState: StateFlow<UserProfile?> get() = _userProfileState
  private val _tasksState = MutableStateFlow<List<Task>>(emptyList())

  val tasksState: StateFlow<List<Task>> get() = _tasksState

  // ... Other properties for different features ...

  private val _loadingState = MutableStateFlow<Boolean>(false)
  val loadingState: StateFlow<Boolean> get() = _loadingState

  init {
    // Initial loading of data for various features
    loadData()
  }

  private fun loadData() {
    viewModelScope.launch(Dispatchers.IO) {
      try {
        _loadingState.emit(true)
        // Fetching user details from a remote server
        val remoteUserDetails = userRepository.fetchUserDetails()
        _userProfileState.emit(processUserProfile(remoteUserDetails))
        // Fetching and processing tasks
        val remoteTasks = taskRepository.fetchTasks()
        _tasksState.emit(processTasks(remoteTasks))
        // ... Load data for other features ...
        // Sending analytics events
        analyticsManager.logEvent("DataLoaded")
      } catch (e: Exception) {
        // Handle errors and update UI accordingly
      } finally {
        _loadingState.emit(false)
      }
    }
  }

  // ... Other methods for processing data, handling user interactions, etc. ...
  private suspend fun processUserProfile(userDetails: UserDetails): UserProfile {
    // Processing user details
    // ...
    return UserProfile(/* Processed user profile data */)
  }

  private suspend fun processTasks(tasks: List<Task>): List<Task> {
    // Processing tasks
    // ...
    return tasks
  }
  // ... Other methods for different features ...
}
```


### 3. Direct Android Framework References
Avoid direct references to Android framework components like Context or View
within the ViewModel. This makes the ViewModel less testable and can lead to
memory leaks. If something needs a Context in the ViewModel, you should
strongly evaluate if that is in the right layer. ViewModels should be designed to
be testable in isolation from the Android framework. Don't get your ViewModel
too tight to a framework, make it as agnostic as possible. A common example is
when we need to access the device Location. See `LocationViewModel` below:

```kotlin 
class LocationViewModel(private val context: Context) : ViewModel() {

  private val _locationState = MutableStateFlow<Location?>(null)
  val locationState: StateFlow<Location?> get() = _locationState

  private val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager

  init {
    // Start listening for location updates
    startLocationUpdates()
  }

  private fun startLocationUpdates() {
    viewModelScope.launch {
      try {
        locationManager.requestLocationUpdates(
          LocationManager.GPS_PROVIDER,
          1000,
          10,
          locationListener
        )
      } catch (e: SecurityException) {
        // Handle permission issues
        _locationState.value = null
      }
    }
  }

  private val locationListener = object : LocationListener {
    // Methods implementation …
  }

}
```

### 4. Extensive Dependencies
A large number of dependencies can increase the coupling between the
ViewModel and external components, such as repositories, managers, or
services. This can reduce the modularity of the code, making it challenging to
isolate and reuse the ViewModel in different contexts or parts of the
application. Besides that, it can make your codebase less flexible and
adaptable to changes. That's because as the ViewModel relies heavily on
specific external components, any changes to those components might
necessitate modifications to the ViewModel, creating a ripple effect across the
codebase. Finally, extensive dependencies often involve complex interactions
with external services or repositories, making it difficult to create isolated unit
tests for the ViewModel. Testing becomes cumbersome and may require
extensive setup, leading to slower and less focused unit tests. The complexity
of dependencies may also hinder the creation of mock objects for testing. See
the example below:

```kotlin
class ExtensiveDependenciesViewModel(
  private val userRepository: UserRepository,
  private val taskRepository: TaskRepository,
  private val analyticsManager: AnalyticsManager,
  private val networkManager: NetworkManager,
  private val locationManager: LocationManager,
  // ... other dependencies ...
) : ViewModel() {

  private val _resultState = MutableStateFlow<Result>(Result.Loading)
  val resultState: StateFlow<Result> get() = _resultState

  init {
    // Initial loading of data for various features
    loadData()
  }

  private fun loadData() {
    viewModelScope.launch(Dispatchers.IO) {
      try {
        // Fetching user details from a remote server
        val remoteUserDetails = userRepository.fetchUserDetails()

        // Fetching and processing tasks
        val remoteTasks = taskRepository.fetchTasks()
        // Sending analytics events
        analyticsManager.logEvent("DataLoaded")
        // Network connectivity check
        if (networkManager.isNetworkConnected()) {
          // Additional logic requiring network connectivity
          // ...
        }
        // Location-related operations
        val currentLocation = locationManager.getCurrentLocation()
        // Combine results and update state
        _resultState.value = combineResults(remoteUserDetails, remoteTasks, currentLocation)
      } catch (e: Exception) {
        // Handle errors and update UI accordingly
        _resultState.value = Result.Error(e.message ?: "An error occurred")
      }
    }
  }

  private suspend fun combineResults(
    userDetails: UserDetails,
    tasks: List<Task>,
    location: Location?
  ): Result {
    // Heavy logic for combining user details, tasks, and location
    // ...
    return Result.Success(/* Combined result data */)
  }

  // ... other methods related to extensive dependencies ...
  companion object {
    // ... constants or other shared properties ...
  }
}

```

Notice that all the symptoms listed above have one thing in common: they make your
ViewModel difficult to test. Understanding that all those symptoms share this common
trait—hindering the testability of your ViewModel—can be the first step toward crafting a
robust and maintainable architecture. Recognizing these signs of a 'diseased'
ViewModel equips you with the insight needed to administer targeted solutions,
ensuring a streamlined testing process and enhancing the overall resilience of your
application.

Now, let's explore the remedies that will not only alleviate the identified symptoms but
also foster a ViewModel that thrives in the realm of effective testing and code quality.

## Treating a diseased ViewModel

Let's consider a hypothetical example of a `BadPracticeViewModel` in Kotlin that
incorporates several bad practices, including heavy logic, extensive dependencies,
direct Android framework reference and a large scope:

```kotlin
@HiltViewModel
class BadPracticeViewModel @Inject constructor(
  context: Context,
  private val userRepository: UserRepository,
  private val taskRepository: TaskRepository,
  private val analyticsManager: AnalyticsManager,
  private val networkManager: NetworkManager,
  // ... other dependencies ...
) : ViewModel() {

  private val locationManager: LocationManager by lazy {
    context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
  }

  private val _resultState = MutableStateFlow<Result>(Result.Loading)
  val resultState: StateFlow<Result> get() = _resultState

  init {
    // Initial loading of data for various features
    loadData()
    startLocationUpdates()
  }

  @SuppressLint("MissingPermission")
  private fun loadData() {
    viewModelScope.launch(Dispatchers.IO) {
      try {
        // Simulate fetching user details from a remote server
        val remoteUserDetails = userRepository.fetchUserDetails()
        // Simulate fetching and processing tasks
        val remoteTasks = taskRepository.fetchTasks()
        // Simulate sending analytics events
        analyticsManager.logEvent("DataLoaded")
        // Simulate network connectivity check
        if (networkManager.isNetworkConnected()) {
          // Additional logic requiring network connectivity
          // ...
        }
  
        // Simulate heavy logic for combining user details, tasks, and location
        val currentLocation = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
        val combinedResult = combineResults(remoteUserDetails, remoteTasks, currentLocation)
  
        // Update state with the combined result
        _resultState.value = combinedResult
      } catch (e: Exception) {
        // Handle errors and update UI accordingly
        _resultState.value = Result.Error(e.message ?: "An error occurred")
      }
    }
  }

  private fun startLocationUpdates() {
    viewModelScope.launch {
      try {
        locationManager.requestLocationUpdates(
          LocationManager.GPS_PROVIDER,
          MIN_TIME_BETWEEN_UPDATES,
          MIN_DISTANCE_CHANGE_FOR_UPDATES,
          locationListener,
        )
      } catch (e: SecurityException) {
        // Handle permission issues
        _resultState.value = Result.Error("Location permission denied")
      }
    }
  }

  private val locationListener = LocationListener {
    // Handle location updates
  }

  private suspend fun combineResults(
    userDetails: UserDetails,
    tasks: List<Task>,
    currentLocation: Location?,
  ): Result {

    // Simulate heavy logic for combining user details and tasks
    // ...
    return Result.Success("$userDetails - ${tasks.first()} - $currentLocation")
  }

  companion object {
    private const val MIN_TIME_BETWEEN_UPDATES: Long = 1000
    private const val MIN_DISTANCE_CHANGE_FOR_UPDATES: Float = 10f
  }

  sealed class Result {
    data object Loading : Result()
    data class Success(val data: String) : Result()
    data class Error(val message: String) : Result()
  }
}
```

As you noticed, we have some bad practices incorporated in the code above.
Now, let's discuss why this example incorporates bad practices, why it's advisable to
avoid such an approach and refactor it following the best practices:


### 1. Heavy Logic
**Issue:** The ViewModel is responsible for fetching data, handling network connectivity
checks, obtaining location updates, and combining results.

**Solution:** Apply the Single Responsibility Principle (SRP) separating each responsibility
to a different code unit.

### 2. Large ViewModel
**Issue:** The ViewModel handles multiple features and operations, resulting in a larger
class with increased complexity.

**Solution:** Considering that we already separated concerns effectively, consider now
breaking down complex UIs into smaller, reusable components or sub-ViewModels. Use
ViewModel composition to combine multiple ViewModels into a single, cohesive UI.
Each sub-ViewModel can be responsible for managing a specific part of the UI, such as
a list item or a form field.

### 3. Direct References to Android Framework Components
**Issue:** The ViewModel directly references the `LocationManager`, tightly coupling it with
Android-specific functionality.

**Solution:** Consider moving them to separate classes outside of the ViewModel. This
could be achieved by using a coordinator or presenter pattern, where the ViewModel
delegates Android-specific operations to dedicated classes. Also, dependency injection
libraries can help with that.

### 4. Extensive Dependencies
**Issue:** The ViewModel depends on multiple external components, including
repositories, managers, and Android framework components.

**Solution:** Introduce use cases or interactors to encapsulate complex business logic and
data operations.


In practice, it's crucial to design ViewModels with a clear separation of concerns,
minimal dependencies, and a focus on managing UI-related concerns. Adopting clean
architecture principles and employing appropriate design patterns can lead to more
maintainable, testable, and scalable code.

After applying some refactorings to the ViewModel above, here's the result:


```kotlin
@HiltViewModel
class BadPracticeViewModel @Inject constructor(
  private val locationManager: LocationManager,
  private val userDetailsAndTasksUseCase: UserDetailsAndTasksUseCase,
  private val userDetailsAndTasksResultMapper: UserDetailsAndTasksResultMapper,
  // ... other dependencies ...
) : ViewModel() {

  private val _resultState = MutableStateFlow<Result>(Result.Loading)
  val resultState: StateFlow<Result> get() = _resultState

  init {
    // Initial loading of data for various features
    loadData()
    startLocationUpdates()
  }

  @SuppressLint("MissingPermission")
  private fun loadData() {
    viewModelScope.launch(Dispatchers.IO) {
      try {
        val (userDetails, tasks, currentLocation) =
        userDetailsAndTasksUseCase.fetchUserDetailsAndTasksWithLocation()
        val combinedResults = userDetailsAndTasksResultMapper.map(userDetails, tasks, currentLocation)
        // Update state with the combined result
        _resultState.value = combinedResults
      } catch (e: Exception) {
        // Handle errors and update UI accordingly
        _resultState.value = Result.Error(e.message ?: "An error occurred")
      }
    }
  }

  private fun startLocationUpdates() {
    viewModelScope.launch {
      try {
        locationManager.requestLocationUpdates(
          LocationManager.GPS_PROVIDER,
          MIN_TIME_BETWEEN_UPDATES,
          MIN_DISTANCE_CHANGE_FOR_UPDATES,
          locationListener,
        )
      } catch (e: SecurityException) {
        // Handle permission issues
        _resultState.value = Result.Error("Location permission denied")
      }
    }
  }

  private val locationListener = LocationListener {
    // Handle location updates
  }

  companion object {
    private const val MIN_TIME_BETWEEN_UPDATES: Long = 1000
    private const val MIN_DISTANCE_CHANGE_FOR_UPDATES: Float = 10f
  }

  sealed class Result {
    data object Loading : Result()
    data class Success(val data: String) : Result()
    data class Error(val message: String) : Result()
  }
}
```

## Diving a little deeper into treatment with States
You could notice the usage of UI State data structures in the previous examples, like the
`sealed class Result``. All these possible Results are immutable and this state is exposed
in one place: `resultState`. This approach is an excellent remedy when treating a
diseased ViewModel that's hard to test because we would have a finite number of
possible view states to validate and a Single Source of Truth (SSOT).

This SSOT approach promotes consistency and reliability in data management within
the application. It helps in maintaining a clear separation of concerns by centralizing
data operations in the ViewModel, which acts as a mediator between the UI and the
underlying data sources. This architecture facilitates the implementation of
Unidirectional Data Flow (UDF), where data flows in a single direction—from the
ViewModel to the UI components—avoiding circular dependencies and ensuring
predictable data flow throughout the application lifecycle.


![Unidirectional Data Flow](/img/demystifying-viewmodel-testing/udf-2.webp)

In the above diagram we can see clearly how the UDF works with ViewModels:

1. The ViewModel holds and exposes UI State;
2. UI notifies ViewModel of events (button click, for example);
3. ViewModel handles the events, updates the state, and is consumed by the UI;
4. Repeat the flow.

Independent of the architecture used: MVVM, MVI, MVP, etc, focus on how to make
your UI Data predictable, immutable, and unidirectional. By doing that, your application
will be easier to understand, test, and maintain, ultimately leading to better user
experiences.

## Conclusion

Crafting test-friendly ViewModels is a common challenge faced by developers, but it can
be overcome with the right approach. By recognizing the symptoms of a poorly
designed ViewModel – such as heavy logic, extensive dependencies, direct references
to Android framework components, and overly large scope – we can take steps to
address these issues and improve the overall quality and maintainability of our
codebase.

Through this journey, we've explored the core principles of ViewModel design and why
adhering to best practices is essential. By applying concepts like the Single
Responsibility Principle, separating concerns, Single Source of Truth, Unidirectional
Data Flow, and employing clean architecture principles, we can refactor our ViewModels
to be more modular, testable, and resilient.

And finally, be patient. Refactor your code little by little with the help of the existing tests.
You don't want a healthy ViewModel with wrong behaviors.

