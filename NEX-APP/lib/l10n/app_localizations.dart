import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const _localizedValues = {
    'en': {
      'welcomeBack': 'Welcome Back',
      'signIn': 'Sign In',
      'email': 'Email',
      'password': 'Password',
      'forgotPassword': 'Forgot Password?',
      'createAccount': 'Create Account',
      'selectLanguage': 'Select Language',
      'language': 'Language',
      'cancel': 'Cancel',
      'update': 'Update',
      'home': 'Home',
    },
    'es': {
      'welcomeBack': 'Bienvenido de nuevo',
      'secureAccess': 'Acceso seguro',
      'signInDescription': 'Inicia sesión para acceder a tu red encriptada y servicios.',
      'signIn': 'Iniciar sesión',
      'email': 'Correo electrónico',
      'password': 'Contraseña',
      'forgotPassword': '¿Olvidaste tu contraseña?',
      'createAccount': 'Crear cuenta',
      'selectLanguage': 'Seleccionar idioma',
      'language': 'Idioma',
      'cancel': 'Cancelar',
      'update': 'Actualizar',
      'home': 'Inicio',
    },
    'fr': {
      'welcomeBack': 'Bienvenue',
      'secureAccess': 'Accès sécurisé',
      'signInDescription': 'Connectez-vous pour accéder à votre réseau chiffré et services.',
      'signIn': 'Connexion',
      'email': 'E-mail',
      'password': 'Mot de passe',
      'forgotPassword': 'Mot de passe oublié?',
      'createAccount': 'Créer un compte',
      'selectLanguage': 'Choisir la langue',
      'language': 'Langue',
      'cancel': 'Annuler',
      'update': 'Mettre à jour',
      'home': 'Accueil',
    },
    'ru': {
      'welcomeBack': 'С возвращением',
      'secureAccess': 'Защищенный доступ',
      'signInDescription': 'Войдите, чтобы получить доступ к вашей зашифрованной сети и сервисам.',
      'signIn': 'Войти',
      'email': 'Электронная почта',
      'password': 'Пароль',
      'forgotPassword': 'Забыли пароль?',
      'createAccount': 'Создать аккаунт',
      'selectLanguage': 'Выбрать язык',
      'language': 'Язык',
      'cancel': 'Отмена',
      'update': 'Обновить',
      'home': 'Главная',
    },
    'de': {
      'welcomeBack': 'Willkommen zurück',
      'secureAccess': 'Sicherer Zugriff',
      'signInDescription': 'Melden Sie sich an, um auf Ihr verschlüsseltes Netzwerk und Dienste zuzugreifen.',
      'signIn': 'Anmelden',
      'email': 'E-Mail',
      'password': 'Passwort',
      'forgotPassword': 'Passwort vergessen?',
      'createAccount': 'Konto erstellen',
      'selectLanguage': 'Sprache auswählen',
      'language': 'Sprache',
      'cancel': 'Abbrechen',
      'update': 'Aktualisieren',
      'home': 'Startseite',
    },
    'ar': {
      'welcomeBack': 'مرحبًا بعودتك',
      'secureAccess': 'الوصول الآمن',
      'signInDescription': 'سجل الدخول للوصول إلى شبكتك المشفرة والخدمات.',
      'signIn': 'تسجيل الدخول',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'forgotPassword': 'هل نسيت كلمة المرور؟',
      'createAccount': 'إنشاء حساب',
      'selectLanguage': 'اختر اللغة',
      'language': 'اللغة',
      'cancel': 'إلغاء',
      'update': 'تحديث',
      'home': 'الرئيسية',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key] ?? key;
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations._localizedValues.containsKey(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
