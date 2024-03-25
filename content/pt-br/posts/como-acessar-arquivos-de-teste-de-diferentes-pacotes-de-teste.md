---
title: "Como acessar arquivos de teste de diferentes pacotes de teste (Unit e Instrumented) em Android"
date: 2022-02-19
lastmod: 2024-03-24
description: "Aprenda como acessar arquivos de teste de diferentes pacotes de teste (Unit e Instrumented) em Android."
featured_image: "/img/how-to-access-test-only-files-from-unit-and-instrumented-test-packages/featured_image.webp"
draft: false 
---

![Arara-canindé com uma asa aberta](/img/how-to-access-test-only-files-from-unit-and-instrumented-test-packages/cover-image-1.webp)

## TL;DR

Crie um diretório chamado `testCommon` e adicione o trecho de código abaixo ao seu arquivo `build.gradle`.

```groovy
android {
    ...
    sourceSets {
        test { java.srcDirs += src/testCommon }
        androidTest { java.srcDirs += src/testCommon }
      }
  }
```

--- 

Você já esteve em uma situação em que precisa acessar arquivos utilitários tanto do pacote `test`
quanto do `androidTest`? Se sim, este artigo pode ser útil para você.

Digamos que você tenha um arquivo chamado `Placeholders.kt` no qual você usa seus valores
como **test doubles** para seus testes de unidade.

Nosso cenário de teste neste caso será o retorno `Success` do método login de uma
classe chamada `LoginUseCaseImpl`.

Por exemplo:

```kotlin
// test/Placeholders.kt
object Placeholders {
    const val email = "johndoe@email.com"
    const val password = "strongpassword123"
  }

// test/LoginUseCaseImplTest.kt
class LoginUseCaseImplTest {

    private val loginUseCase = LoginUseCaseImpl()

    @Test
    fun `when call login should return Success`() {
        // Arrange
        val email = Placeholders.email
        val password = Placeholders.password

        // Act
        val result = loginUseCase.login(email, password)

        // Assert
        assertEquals(Success, result)
    }
}
```

Agora, precisamos escrever **Testes instrumentados** usando [Espresso](https://developer.android.com/training/testing/espresso/)
para validar o fluxo de login completo. O cenário é: ao preencher os campos de e-mail e senha e tocar no botão de login
então uma mensagem de sucesso será exibida.

```kotlin
// androidTest/LoginScreenInstrumentedTest.kt 
class LoginScreenInstrumentedTest {
    @Test
    fun when_fill_the_email_and_password_fields_and_tap_the_login_button_then_a_success_message_will_display() {
        // Arrange
        val email = Placeholders.email
        val password = Placeholders.password

        // When fill email and password fields
        onView(withId(R.id.email_field)).perform(ViewActions.typeText(email))
        onView(withId(R.id.password_field)).perform(ViewActions.typeText(password))

        // And tap the login button
        onView(withId(R.id.login_button)).perform(ViewActions.click())

        // Then a success message will display.
        onView(withId(R.id.success_message)).check(matches(isDisplayed()))
    }
}
```

Por padrão, o teste utilizando o Espresso estará dentro do pacote `androidTest`, mas nosso `Placeholders.kt`
está disponível apenas dentro do pacote `test`, no qual nosso `LoginUseCaseImplTest` também está localizado.
Portanto, o Teste Instrumentado acima não encontrará o `Placeholders.kt`.

Para permitir que ambos os testes acessem o mesmo arquivo, precisamos criar um novo pacote dentro do `src` que iremos colocar o `Placeholders.kt`.
Neste exemplo, vamos nomeá-lo como `testCommon`. Depois disso, precisamos dizer ao gradle para considerar este novo pacote
como um pacote `test` e `androidTest`. Colocaremos o código abaixo em nosso arquivo `build.gradle`:

```groovy
android {
    ...
    sourceSets {
        test { java.srcDirs += src/testCommon }
        androidTest { java.srcDirs += src/testCommon }
      }
  }
```

É isso! Agora ambos os pacotes de teste poderão acessar nosso arquivo `Placeholders.kt`!
