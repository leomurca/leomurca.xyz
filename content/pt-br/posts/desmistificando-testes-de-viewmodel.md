---
title: "Desmistificando os testes de ViewModel: estratégias para criar ViewModels fáceis de testar"
date: 2024-03-25T10:54:21-03:00
description: "Aprenda as melhores práticas para escrever testes para seu ViewModel."
featured_image: "/img/demystifying-viewmodel-testing/featured_image.webp"
draft: false
---

![Um papagaio verde](/img/demystifying-viewmodel-testing/cover-image-1.webp)

## Introdução

Você já teve dificuldades ao escrever testes unitários para seu ViewModel? Dificuldades ao 
escrever testes são um GRANDE sintoma de que seu ViewModel está mal escrito. Se o simples 
pensamento de testar seu ViewModel te causa arrepios ou se você se vê lutando com setups 
complicados apenas para verificar um comportamento simples, não tema – você não está sozinho. 
Escrever ViewModels amigáveis aos testes é um desafio comum enfrentado por muitos desenvolvedores, 
mas a boa notícia é que é um desafio que pode ser superado.

Neste post, exploraremos as razões por trás da luta nos testes, desvendando as complexidades 
do design de ViewModel que levam a dores de cabeça nos testes. Mais importante ainda, iremos equipá-lo 
com insights e técnicas práticas para transformar seus ViewModels em unidades amigáveis aos testes, tornando 
o processo de teste unitário uma experiência fluida e eficiente. Vamos embarcar em uma jornada para banir as 
preocupações com testes e elevar o seu jogo de ViewModel!

## O que é um ViewModel?


Primeiramente, precisamos definir o que é um ViewModel e qual é o seu propósito de existência. De acordo com a 
[Visão geral do ViewModel](https://developer.android.com/topic/libraries/architecture/viewmodel): *"[…] a classe ViewModel 
é um detentor de estado da tela ou da lógica de negócios"*. Em outras palavras, ele encapsula a lógica de negócios 
relacionada e expõe o Estado da Interface do Usuário da Tela.

No entanto, qualquer classe Kotlin simples pode ser usada como uma detentora de estado (StateHolder) para encapsular a lógica 
de negócios e expor algum Estado da Interface do Usuário da Tela. Então, por que precisamos de ViewModels?

A principal razão pela qual usamos um ViewModel em vez de uma classe Kotlin simples é que os ViewModels:

- Sobrevivem a mudanças de configuração (conscientes do ciclo de vida). Essas mudanças de configuração estão relacionadas 
a um benefício de persistência de dados ao usar ViewModels.
- Possuem ótima integração com o Jetpack e outras bibliotecas;
- Fazem cache de estados.

Conhecendo a definição de um ViewModel e os motivos pelos quais devemos usá-lo, devemos implementá-lo e mantê-lo com muito 
cuidado. E caso seu ViewModel já exista, preste atenção nos sintomas que podem indicar que ele precisa de alguns cuidados.

## Sintomas que indicam que seu ViewModel precisa de alguns cuidados

### 1. Lógica Pesada
Ter lógica de negócios complexa ou manipulação extensa de dados diretamente no ViewModel pode ser um ótimo indicador de que 
seu ViewModel precisa de atenção. Este sintoma causará muitas dores de cabeça ao testá-lo e mantê-lo. Observe o 
`UserProfileViewModel` abaixo, por exemplo:

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

### 2. ViewModels grandes demais
Uma classe grande é um [code smell](https://martinfowler.com/bliki/CodeSmell.html) bem conhecido para classes que têm muitas responsabilidades. 
Isso não é diferente para ViewModels. A única responsabilidade do ViewModel é gerenciar os dados da UI. Ter ViewModels excessivamente grandes 
com muitas responsabilidades pode dificultar a compreensão, o teste e a manutenção do código. Esteja ciente de que seguir o 
[SRP](https://blog.cleancoder.com/uncle-bob/2014/05/08/SingleReponsibilityPrinciple.html) também é fundamental para ViewModels. 
Veja o exemplo abaixo com muitas responsabilidades para um único ViewModel:

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

### 3. Referências diretas do Framework Android
Evite referências diretas a componentes da estrutura Android, como Context ou View, no ViewModel. Isso torna o ViewModel 
menos testável e pode levar a memory leaks. Se algo precisa de um `context` no ViewModel, você deve avaliar fortemente 
se ele está na camada correta. ViewModels devem ser projetados para serem testáveis isoladamente da estrutura Android. 
Não deixe seu ViewModel muito preso a uma estrutura, torne-o o mais agnóstico possível. Um exemplo comum é quando 
precisamos acessar a localização do dispositivo. Veja `LocationViewModel` abaixo:

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

### 4. Dependências Extensas
Um grande número de dependências pode aumentar o acoplamento entre o ViewModel e componentes externos, como repositórios, 
gerenciadores ou serviços. Isso pode reduzir a modularidade do código, tornando difícil isolar e reutilizar o ViewModel 
em diferentes contextos ou partes do aplicativo. Além disso, pode tornar sua base de código menos flexível e adaptável 
a mudanças. Isso ocorre porque, como o ViewModel depende muito de componentes externos específicos, qualquer alteração 
nesses componentes pode exigir modificações no ViewModel, criando um efeito cascata em toda a base de código. 

Por fim, dependências extensas geralmente envolvem interações complexas com serviços ou repositórios externos, dificultando 
a criação de testes unitários isolados para o ViewModel. Os testes tornam-se complicados e podem exigir configurações extensas, 
resultando em testes unitários mais lentos e menos focados. A complexidade das dependências também pode dificultar a 
criação de objetos simulados para teste. Veja o exemplo abaixo:

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


Observe que todos os sintomas listados acima têm uma coisa em comum: eles dificultam o teste do seu ViewModel. Compreender 
que todos esses sintomas compartilham essa característica comum – dificultando a testabilidade do seu ViewModel – pode ser 
o primeiro passo para a criação de uma arquitetura robusta e de fácil manutenção. Reconhecer esses sinais de um ViewModel 
“doente” fornece a você o conhecimento necessário para administrar soluções direcionadas, garantindo um processo de teste 
simplificado e melhorando a resiliência geral do seu aplicativo.

Agora, vamos explorar as soluções que não apenas aliviarão os sintomas identificados, mas também promoverão um ViewModel 
que prospere no domínio dos testes eficazes e da qualidade do código.

### Tratando um ViewModel doente
Vamos considerar um exemplo hipotético: `BadPracticeViewModel` em Kotlin que incorpora várias práticas ruins, incluindo 
lógica pesada, dependências extensas, referência direta à estrutura Android e um escopo grande:

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
Como você percebeu, temos algumas práticas inadequadas incorporadas no código acima. Agora, vamos discutir 
por que este exemplo incorpora más práticas, por que é aconselhável evitar tal abordagem e refatorá-la seguindo 
as melhores práticas:

### 1. Lógica pesada
**Problema:** O ViewModel é responsável por buscar dados, lidar com a conectividade de rede
verificações, obtenção de atualizações de localização e combinação de resultados.

**Solução:** Aplique o Princípio da Responsabilidade Única (SRP), separando cada 
responsabilidade em uma unidade de código diferente.


### 2. ViewModel grande demais
**Problema:** o ViewModel lida com vários recursos e operações, resultando em uma classe maior com maior complexidade.

**Solução:** Considerando que já separamos as preocupações de forma eficaz, considere agora dividir UIs complexas 
em componentes menores e reutilizáveis ou subViewModels. Use a composição do ViewModel para combinar vários 
ViewModels em uma UI única e coesa. Cada sub-ViewModel pode ser responsável por gerenciar uma parte específica da 
UI, como um item de lista ou um campo de formulário.

### 3. Referências diretas do Framework Android
**Problema:** o ViewModel faz referência direta ao `LocationManager`, acoplando-o fortemente à funcionalidade específica do Android.

**Solução:** considere movê-los para classes separadas fora do ViewModel. Isso poderia ser conseguido usando um padrão presenter, onde 
o ViewModel delega operações específicas do Android para classes dedicadas. Além disso, bibliotecas de injeção de dependência podem ajudar nisso.

### 4. Dependências Extensas
**Problema:** o ViewModel depende de vários componentes externos, incluindo repositórios, gerenciadores e componentes do Framework Android.

**Solução:** introduza [use cases](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) 
ou [interactors](https://proandroiddev.com/why-you-need-use-cases-interactors-142e8a6fe576) para encapsular lógica de negócios complexa 
e operações de dados.

Na prática, é crucial projetar ViewModels com uma separação clara de preocupações, dependências mínimas e foco no gerenciamento de preocupações 
relacionadas à UI. Adotar princípios de arquitetura limpa e empregar padrões de design apropriados pode levar a um código mais sustentável, 
testável e escalonável.

Depois de aplicar algumas refatorações ao ViewModel acima, aqui está o resultado:

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
## Aprofundando-se um pouco mais no tratamento com os Estados

Você pode notar o uso de estruturas de dados para gerencia estados da UI nos exemplos anteriores, como o `sealed class Result`. 
Todos esses resultados possíveis são imutáveis e este estado é exposto em um só lugar: `resultState`. Essa abordagem é um excelente 
remédio ao tratar um ViewModel doente que é difícil de testar porque teríamos um número finito de estados da View possíveis para 
validar e uma [Fonte Única de Verdade (SSOT)](https://developer.android.com/topic/architecture?hl=pt-br#single-source-of-truth).

Esta abordagem SSOT promove consistência e confiabilidade no gerenciamento de dados dentro do aplicativo. Ajuda a manter uma 
separação clara de preocupações, centralizando as operações de dados no ViewModel, que atua como um mediador entre a UI e as 
fontes de dados subjacentes. Essa arquitetura facilita a implementação do 
[Fluxo de Dados Unidirecional (UDF)](https://developer.android.com/topic/architecture?hl=pt-br#unidirectional-data-flow), onde os dados 
fluem em uma única direção — do ViewModel aos componentes da UI — evitando dependências circulares e garantindo um fluxo de dados 
previsível durante todo o ciclo de vida do aplicativo.

![Fluxo de Dados Unidirecional](/img/demystifying-viewmodel-testing/udf-2.webp)

No diagrama acima podemos ver claramente como o UDF funciona com ViewModels:

1. O ViewModel mantém e expõe o estado da UI;
2. A UI notifica o ViewModel sobre eventos (clique do botão, por exemplo);
3. ViewModel trata os eventos, atualiza o estado e é consumido pela UI;
4. Repita o fluxo.

Independente da arquitetura utilizada: MVVM, MVI, MVP, etc, concentre-se em como tornar seus dados de UI previsíveis, imutáveis e unidirecionais. 
Ao fazer isso, seu aplicativo será mais fácil de entender, testar e manter, resultando em melhores experiências do usuário.

## Conclusão

Criar ViewModels fáceis de testar é um desafio comum enfrentado pelos desenvolvedores, mas pode ser superado com a abordagem certa. Ao reconhecer 
os sintomas de um ViewModel mal projetado – como lógica pesada, dependências extensas, referências diretas a componentes do Framework Android e 
escopo excessivamente grande – podemos tomar medidas para resolver esses problemas e melhorar a qualidade geral e a capacidade de manutenção 
de nossa base de código.

Nesta jornada, exploramos os princípios básicos do design do ViewModel e por que aderir às práticas recomendadas é essencial. Ao aplicar conceitos 
como o Princípio de Responsabilidade Única(SRP), Separação de Preocupações(SOC), Fonte Única de Verdade(SSOT), Fluxo de Dados Unidirecional(UDF) 
e empregar princípios de arquitetura limpa, podemos refatorar nossos ViewModels para serem mais modulares, testáveis e resilientes.

E finalmente, seja paciente. Refatore seu código aos poucos com a ajuda dos testes existentes. Você não quer um ViewModel saudável com comportamentos errados.
