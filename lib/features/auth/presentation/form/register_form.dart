// lib/features/auth/presentation/form/register_form.dart
import 'package:disfruta_antofagasta/features/auth/presentation/state/register/register_provider.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/config/theme/theme_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _registerObscureProvider = StateProvider.autoDispose<bool>((_) => true);

class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({super.key});

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(registerFormProvider.notifier).bootstrap());
  }

  Future<void> _submit() async {
    final s0 = ref.read(registerFormProvider);
    if (s0.isPosting) return;
    await ref.read(registerFormProvider.notifier).submit();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(registerFormProvider);
    final n = ref.read(registerFormProvider.notifier);
    final obscure = ref.watch(_registerObscureProvider);

    final hasCountry = s.selectedCountry != null;

    // ✅ Regla nueva: Región SOLO si el país lo requiere
    final showRegion = hasCountry && s.needsRegion;

    final regionEnabled = showRegion && !s.isPosting && !s.isLoadingRegions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _rounded(
                hint: 'Nombre',
                onChanged: (v) => n.setField('name', v),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _rounded(
                hint: 'Apellido',
                onChanged: (v) => n.setField('last', v),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: _rounded(
                hint: 'Edad',
                keyboard: const TextInputType.numberWithOptions(
                  signed: false,
                  decimal: false,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                onChanged: (v) => n.setField('age', v),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  final nn = int.tryParse(v);
                  if (nn == null) return 'Solo números';
                  if (nn <= 1) return 'Mayor a 1';
                  if (nn > 120) return 'Edad inválida';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: _rounded(
                hint: 'Días de visita',
                keyboard: const TextInputType.numberWithOptions(
                  signed: false,
                  decimal: false,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                onChanged: (v) => n.setField('stay', v),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  final nn = int.tryParse(v);
                  if (nn == null) return 'Solo números';
                  if (nn <= 0) return 'Debe ser > 0';
                  if (nn > 365) return 'Máx 365';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _rounded(
          hint: 'Correo electrónico',
          keyboard: TextInputType.emailAddress,
          onChanged: (v) => n.setField('email', v),
        ),
        const SizedBox(height: 12),

        _rounded(
          hint: 'Contraseña',
          obscure: obscure,
          suffix: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: () =>
                ref.read(_registerObscureProvider.notifier).state = !obscure,
          ),
          onChanged: (v) => n.setField('pass', v),
        ),
        const SizedBox(height: 12),

        // ✅ País
        DropdownButtonFormField<Country>(
          value: s.selectedCountry,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.black87,
          ),
          iconEnabledColor: Colors.black87,
          iconDisabledColor: Colors.black38,
          style: const TextStyle(color: Colors.black),
          hint: Text(
            s.isLoadingCountries ? 'Cargando países…' : 'País',
            style: const TextStyle(color: Colors.black54),
          ),
          decoration: _decoration(
            'País',
            prefix: const Icon(Icons.public_outlined),
            suffix: s.isLoadingCountries
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          items: s.countries
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(
                    c.name,
                    style: const TextStyle(color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (s.isPosting || s.isLoadingCountries)
              ? null
              : n.countryChanged,
        ),

        // ✅ Región SOLO si aplica (Chile/Perú). Si Argentina -> no se renderiza.
        if (showRegion) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: s.selectedRegionId,
            isExpanded: true,
            dropdownColor: Colors.white,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.black87,
            ),
            iconEnabledColor: Colors.black87,
            iconDisabledColor: Colors.black38,
            style: const TextStyle(color: Colors.black),
            hint: const Text('Región', style: TextStyle(color: Colors.black54)),
            decoration: _decoration(
              'Región',
              prefix: const Icon(Icons.map_outlined),
              suffix: (s.isLoadingRegions)
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
            items: s.regions
                .map(
                  (r) => DropdownMenuItem(
                    value: r.id,
                    child: Text(
                      r.name,
                      style: const TextStyle(color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: regionEnabled ? n.regionChanged : null,
          ),
        ],

        const SizedBox(height: 12),

        // ✅ Tipo de visitante
        DropdownButtonFormField<String>(
          value: s.visitorType,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.black87,
          ),
          iconEnabledColor: Colors.black87,
          iconDisabledColor: Colors.black38,
          style: const TextStyle(color: Colors.black),
          hint: const Text(
            'Tipo de visitante',
            style: TextStyle(color: Colors.black54),
          ),
          decoration: _decoration(
            'Tipo de visitante',
            prefix: const Icon(Icons.badge_outlined),
          ),
          items: const [
            DropdownMenuItem(
              value: 'rapanui',
              child: Text(
                'Local (RapaNui)',
                style: TextStyle(color: Colors.black87),
              ),
            ),
            DropdownMenuItem(
              value: 'continental',
              child: Text(
                'Continental',
                style: TextStyle(color: Colors.black87),
              ),
            ),
            DropdownMenuItem(
              value: 'foreign',
              child: Text(
                'Extranjero',
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ],
          onChanged: s.isPosting
              ? null
              : (v) {
                  if (v == null) return;
                  n.visitorTypeChanged(v);
                },
        ),
        const SizedBox(height: 12),

        if (s.error != null) ...[
          Text(s.error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
        ],

        SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.panelWine,
              foregroundColor: AppColors.textOnPanel,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            onPressed: s.isPosting ? null : _submit,
            child: Text(s.isPosting ? 'Creando…' : 'Crear cuenta'),
          ),
        ),
      ],
    );
  }

  Widget _rounded({
    required String hint,
    TextInputType? keyboard,
    bool obscure = false,
    Widget? suffix,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      cursorColor: Colors.black,
      style: const TextStyle(color: Colors.black),
      onChanged: onChanged,
      keyboardType: keyboard,
      obscureText: obscure,
      inputFormatters: inputFormatters,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      decoration: _decoration(hint, suffix: suffix),
    );
  }

  InputDecoration _decoration(String hint, {Widget? prefix, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black54),
      prefixIcon: prefix,
      prefixIconColor: Colors.black45,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.92),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        borderSide: BorderSide(color: Color(0xFF0E4560), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        borderSide: BorderSide(color: Colors.red, width: 1.2),
      ),
    );
  }
}
