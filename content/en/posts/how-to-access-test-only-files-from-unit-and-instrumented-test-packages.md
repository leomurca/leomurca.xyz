---
title: "How to Access Test Only Files From Unit and Instrumented Test Packages"
date: 2022-02-19
description: "Learn how to make files available from different test packages in Android development."
featured_image: "/img/how-to-access-test-only-files-from-unit-and-instrumented-test-packages/featured_image.webp"
draft: false 
---

## TL;DR

Create a directory called `testCommon` and add the code below to your `build.gradle` file.

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

Have you ever been in a situation where you need to access util files from both `test`
and `androidTest` packages? If so, this article may be useful for you.

Let's say that you have a file called `Placeholders.kt` which you use its values
as **test doubles** for your unit tests. 

Our test scenario in this case will be the `Success` return of the login method from an 
use case class called `LoginUseCaseImpl`.

For example:

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

Now, we need to write **Instrumented Tests** using [Espresso](https://developer.android.com/training/testing/espresso/)
to validate the complete login flow. The scenario is: when fill the email and password fields and tap the login button 
then a success message will display.

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

By default, the espresso test will be inside the `androidTest` package but our `Placeholders.kt` 
is available only inside the `test` package, which our `LoginUseCaseImplTest` is also located.
So, the Instrumented Test above will not find the `Placeholders.kt`.

To allow both tests access the same file, we need to create a new package inside `src` which we will place the `Placeholders.kt`.
In this example, we'll name it as `testCommon`. After that, we need to tell gradle to consider this new package
as a `test` and `androidTest` package. We will put the code below in our `build.gradle` file:

```groovy
android {
    ...
    sourceSets {
        test { java.srcDirs += src/testCommon }
        androidTest { java.srcDirs += src/testCommon }
      }
  }
```

That's it! Now both test packages will be able to access our `Placeholders.kt` file!
