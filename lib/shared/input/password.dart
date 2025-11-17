import 'package:formz/formz.dart';

enum PasswordError { empty, length, format, mismatch }

class Password extends FormzInput<String, PasswordError> {
  static final RegExp passwordRegExp = RegExp(
    r'(?:(?=.*\d)|(?=.*\W+))(?![.\n])(?=.*[a-z]).*$',
  );

  final PasswordError? customError; // 🔹 Permite errores forzados como mismatch

  const Password.pure() : customError = null, super.pure('');

  // ignore: use_super_parameters
  const Password.dirty(String value, {this.customError}) : super.dirty(value);

  @override
  PasswordError? validator(String value) {
    if (value.isEmpty || value.trim().isEmpty) return PasswordError.empty;
    if (value.length < 6) return PasswordError.length;
    return null; // 🔹 No validamos mismatch aquí
  }

  // 📌 🔹 Aquí sobreescribimos isValid para que considere el customError
  @override
  bool get isValid {
    return super.isValid && customError == null;
  }

  // 📌 Manejo de mensajes de error
  String? get errorMessage {
    final error = customError ?? displayError;
    if (isValid || isPure) return null;

    switch (error) {
      case PasswordError.empty:
        return 'El campo es requerido';
      case PasswordError.length:
        return 'Mínimo 6 caracteres';
      case PasswordError.mismatch:
        return 'Las contraseñas no coinciden';
      default:
        return null;
    }
  }

  // 📌 Permite copiar el objeto y forzar un error como mismatch
  Password copyWith({String? value, PasswordError? error}) {
    return Password.dirty(value ?? this.value, customError: error);
  }
}
