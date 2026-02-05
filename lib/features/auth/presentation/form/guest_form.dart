// lib/features/auth/presentation/form/guest_form.dart
import 'package:disfruta_antofagasta/features/auth/presentation/state/guest/guest_provider.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/config/theme/theme_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GuestForm extends ConsumerStatefulWidget {
  const GuestForm({super.key});

  @override
  ConsumerState<GuestForm> createState() => _GuestFormState();
}

class _GuestFormState extends ConsumerState<GuestForm> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(guestFormProvider.notifier).bootstrap());
  }

  bool _isLocalVisitor(String? v) =>
      v == 'local_rapanui' || v == 'local_no_rapanui';

  Future<void> _submit() async {
    final s0 = ref.read(guestFormProvider);
    if (!s0.canSubmit || s0.isPosting) return;
    await ref.read(guestFormProvider.notifier).submit();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(guestFormProvider);
    final n = ref.read(guestFormProvider.notifier);

    final hasCountry = s.selectedCountry != null;

    // ✅ Región SOLO si el país lo requiere
    final showRegion = hasCountry && s.needsRegion;
    final regionEnabled = showRegion && !s.isPosting && !s.isLoadingRegions;

    final disableStay = _isLocalVisitor(s.visitorType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          style: const TextStyle(color: Colors.black),
          initialValue: s.name,
          onChanged: n.nameChanged,
          decoration: _glassInput(
            'Nombre',
            prefix: const Icon(Icons.person_outline),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Requerido';
            return null;
          },
        ),
        const SizedBox(height: 12),

        TextFormField(
          style: const TextStyle(color: Colors.black),
          initialValue: s.age?.toString() ?? '',
          onChanged: n.ageChanged,
          keyboardType: const TextInputType.numberWithOptions(
            signed: false,
            decimal: false,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Requerido';
            final x = int.tryParse(v);
            if (x == null) return 'Solo números';
            if (x <= 1) return 'Debe ser > 1';
            if (x > 120) return 'Edad inválida';
            return null;
          },
          decoration: _glassInput(
            'Edad',
            prefix: const Icon(Icons.cake_outlined),
            suffixText: 'años',
          ),
        ),
        const SizedBox(height: 12),

        // ✅ Tipo de visitante (debajo de Edad)
        DropdownButtonFormField<String>(
          value: (s.visitorType == null || s.visitorType!.trim().isEmpty)
              ? null
              : s.visitorType,
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
          decoration: _glassInput(
            'Tipo de visitante',
            prefix: const Icon(Icons.badge_outlined),
          ),
          items: const [
            DropdownMenuItem(
              value: 'local_rapanui',
              child: Text(
                'Local (RapaNui)',
                style: TextStyle(color: Colors.black87),
              ),
            ),
            DropdownMenuItem(
              value: 'local_no_rapanui',
              child: Text(
                'Local no RapaNui',
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
              value: 'extranjero',
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
          decoration: _glassInput(
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

        // ✅ Región SOLO si aplica
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
            decoration: _glassInput(
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

        // ✅✅ AHORA: Días de visita al FINAL (último input antes del botón)
        const SizedBox(height: 12),
        TextFormField(
          enabled: !disableStay && !s.isPosting,
          style: TextStyle(
            color: (!disableStay && !s.isPosting)
                ? Colors.black
                : Colors.black38,
          ),
          initialValue: s.stay?.toString() ?? '',
          onChanged: (!disableStay && !s.isPosting) ? n.daysStayChanged : null,
          keyboardType: const TextInputType.numberWithOptions(
            signed: false,
            decimal: false,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (v) {
            // ✅ Si es Local, NO exigir días
            if (disableStay) return null;

            if (v == null || v.trim().isEmpty) return 'Requerido';
            final x = int.tryParse(v);
            if (x == null) return 'Solo números';
            if (x <= 0) return 'Debe ser > 0';
            if (x > 365) return 'Máx 365';
            return null;
          },
          decoration: _glassInput(
            'Días de visita',
            prefix: const Icon(Icons.today_outlined),
            suffixText: 'días',
            enabled: !disableStay && !s.isPosting,
          ),
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
            onPressed: (s.canSubmit && !s.isPosting) ? _submit : null,
            child: Text(s.isPosting ? 'Entrando…' : 'Entrar como invitado'),
          ),
        ),
      ],
    );
  }

  InputDecoration _glassInput(
    String hint, {
    Widget? prefix,
    String? suffixText,
    Widget? suffix,
    bool enabled = true,
  }) {
    final fill = enabled
        ? Colors.white.withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.55);

    final hintColor = enabled ? Colors.black54 : Colors.black38;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor),
      prefixIcon: prefix,
      prefixIconColor: enabled ? Colors.black45 : Colors.black26,
      suffixIcon: suffix,
      suffixIconColor: enabled ? Colors.black45 : Colors.black26,
      suffixText: suffixText,
      suffixStyle: TextStyle(color: hintColor),
      labelStyle: const TextStyle(color: Colors.black),
      filled: true,
      fillColor: fill,
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
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        borderSide: BorderSide(color: Colors.red, width: 1.2),
      ),
    );
  }
}
