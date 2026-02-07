import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../utils/snackbar_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _documentoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _direccionController = TextEditingController();
  final _ciudadController = TextEditingController();

  String _tipoDocumento = 'CC';
  String? _genero;
  DateTime? _fechaNacimiento;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  bool _isLoading = false;
  
  int _currentStep = 0;
  final int _totalSteps = 4;

  @override
  void dispose() {
    _pageController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _documentoController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() {
        _fechaNacimiento = picked;
      });
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Información personal
        return _nombreController.text.isNotEmpty &&
               _apellidoController.text.isNotEmpty &&
               _emailController.text.isNotEmpty &&
               _emailController.text.contains('@');
      case 1: // Documentación
        return _documentoController.text.isNotEmpty;
      case 2: // Ubicación (opcional, siempre válido)
        return true;
      case 3: // Seguridad
        return _passwordController.text.length >= 8 &&
               _passwordController.text == _passwordConfirmController.text;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < _totalSteps - 1) {
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _handleRegister();
      }
    } else {
      SnackBarHelper.warning(
        context,
        'Por favor completa los campos requeridos',
        title: 'Campos Incompletos',
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.register(
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      email: _emailController.text.trim(),
      telefono: _telefonoController.text.trim(),
      tipoDocumento: _tipoDocumento,
      documento: _documentoController.text.trim(),
      password: _passwordController.text,
      passwordConfirm: _passwordConfirmController.text,
      fechaNacimiento: _fechaNacimiento,
      genero: _genero,
      direccion: _direccionController.text.trim(),
      ciudad: _ciudadController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (result['success'] == true) {
      SnackBarHelper.success(
        context,
        result['message'] ?? 'Registro exitoso',
        title: '¡Bienvenido!',
      );
      
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      SnackBarHelper.error(
        context,
        result['message'] ?? 'Error al registrar',
        title: 'Error de Registro',
      );
    }
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: isCompleted || isActive
                          ? AppColors.primary
                          : AppColors.lightGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.primary
                        : isActive
                            ? AppColors.primary
                            : AppColors.lightGray,
                    shape: BoxShape.circle,
                  ),
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: AppColors.white,
                        )
                      : Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? AppColors.white
                                  : AppColors.sonicSilver,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                if (index < _totalSteps - 1)
                  Expanded(
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.primary
                            : AppColors.lightGray,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.catamaran(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.richBlack,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.rubik(
            fontSize: 14,
            color: AppColors.sonicSilver,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header con botón de volver
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _previousStep,
                      color: AppColors.richBlack,
                    ),
                    const Spacer(),
                    Text(
                      'Paso ${_currentStep + 1} de $_totalSteps',
                      style: GoogleFonts.rubik(
                        fontSize: 14,
                        color: AppColors.sonicSilver,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Indicador de pasos
              _buildStepIndicator(),
              
              // Contenido del formulario
              Expanded(
                child: Form(
                  key: _formKey,
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Paso 1: Información Personal
                      _buildPersonalInfoStep(),
                      
                      // Paso 2: Documentación
                      _buildDocumentationStep(),
                      
                      // Paso 3: Ubicación
                      _buildLocationStep(),
                      
                      // Paso 4: Seguridad
                      _buildSecurityStep(),
                    ],
                  ),
                ),
              ),
              
              // Botones de navegación
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black10,
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.primary),
                          ),
                          child: Text(
                            'Atrás',
                            style: GoogleFonts.rubik(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      flex: _currentStep > 0 ? 1 : 1,
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  _currentStep == _totalSteps - 1
                                      ? 'Registrarse'
                                      : 'Siguiente',
                                  style: GoogleFonts.rubik(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Paso 1: Información Personal
  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepTitle(
            'Información Personal',
            'Completa tus datos básicos',
          ),
          const SizedBox(height: 40),
          
          TextFormField(
            controller: _nombreController,
            decoration: InputDecoration(
              labelText: 'Nombre *',
              prefixIcon: const Icon(Icons.person_outline),
              filled: true,
              fillColor: AppColors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _apellidoController,
            decoration: InputDecoration(
              labelText: 'Apellido *',
              prefixIcon: const Icon(Icons.person_outline),
              filled: true,
              fillColor: AppColors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email *',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: AppColors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo requerido';
              }
              if (!value.contains('@')) {
                return 'Email inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _telefonoController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Teléfono',
              prefixIcon: const Icon(Icons.phone_outlined),
              filled: true,
              fillColor: AppColors.white,
              helperText: 'Opcional',
            ),
          ),
        ],
      ),
    );
  }

  // Paso 2: Documentación
  Widget _buildDocumentationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepTitle(
            'Documentación',
            'Información de identificación',
          ),
          const SizedBox(height: 40),
          
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _tipoDocumento,
                  decoration: InputDecoration(
                    labelText: 'Tipo Doc. *',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    filled: true,
                    fillColor: AppColors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'CC', child: Text('CC')),
                    DropdownMenuItem(value: 'CE', child: Text('CE')),
                    DropdownMenuItem(value: 'PA', child: Text('PA')),
                    DropdownMenuItem(value: 'TI', child: Text('TI')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _tipoDocumento = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _documentoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Número de Documento *',
                    filled: true,
                    fillColor: AppColors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo requerido';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          InkWell(
            onTap: _selectDate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Fecha de Nacimiento',
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                filled: true,
                fillColor: AppColors.white,
                suffixIcon: const Icon(Icons.arrow_drop_down),
                helperText: 'Opcional',
              ),
              child: Text(
                _fechaNacimiento == null
                    ? 'Seleccionar fecha'
                    : '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}',
                style: TextStyle(
                  color: _fechaNacimiento == null
                      ? AppColors.sonicSilver
                      : AppColors.richBlack,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          DropdownButtonFormField<String>(
            value: _genero,
            decoration: InputDecoration(
              labelText: 'Género',
              prefixIcon: const Icon(Icons.person_outline),
              filled: true,
              fillColor: AppColors.white,
              helperText: 'Opcional',
            ),
            items: const [
              DropdownMenuItem(value: 'M', child: Text('Masculino')),
              DropdownMenuItem(value: 'F', child: Text('Femenino')),
              DropdownMenuItem(value: 'O', child: Text('Otro')),
            ],
            onChanged: (value) {
              setState(() {
                _genero = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // Paso 3: Ubicación
  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepTitle(
            'Ubicación',
            'Información de dirección (opcional)',
          ),
          const SizedBox(height: 40),
          
          TextFormField(
            controller: _direccionController,
            decoration: InputDecoration(
              labelText: 'Dirección',
              prefixIcon: const Icon(Icons.home_outlined),
              filled: true,
              fillColor: AppColors.white,
              helperText: 'Opcional',
            ),
          ),
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _ciudadController,
            decoration: InputDecoration(
              labelText: 'Ciudad',
              prefixIcon: const Icon(Icons.location_city_outlined),
              filled: true,
              fillColor: AppColors.white,
              helperText: 'Opcional',
            ),
          ),
          const SizedBox(height: 40),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary20),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Esta información es opcional y puede completarse más tarde.',
                    style: GoogleFonts.rubik(
                      fontSize: 13,
                      color: AppColors.richBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Paso 4: Seguridad
  Widget _buildSecurityStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepTitle(
            'Seguridad',
            'Crea una contraseña segura',
          ),
          const SizedBox(height: 40),
          
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Contraseña *',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              filled: true,
              fillColor: AppColors.white,
              helperText: 'Mínimo 8 caracteres',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo requerido';
              }
              if (value.length < 8) {
                return 'Mínimo 8 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _passwordConfirmController,
            obscureText: _obscurePasswordConfirm,
            decoration: InputDecoration(
              labelText: 'Confirmar Contraseña *',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePasswordConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePasswordConfirm = !_obscurePasswordConfirm;
                  });
                },
              ),
              filled: true,
              fillColor: AppColors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo requerido';
              }
              if (value != _passwordController.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text(
                      'Requisitos de contraseña',
                      style: GoogleFonts.rubik(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPasswordRequirement(
                  'Mínimo 8 caracteres',
                  _passwordController.text.length >= 8,
                ),
                _buildPasswordRequirement(
                  'Las contraseñas coinciden',
                  _passwordController.text.isNotEmpty &&
                      _passwordController.text == _passwordConfirmController.text,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirement(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check : Icons.close,
            size: 16,
            color: isValid ? AppColors.success : AppColors.sonicSilver,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.rubik(
              fontSize: 13,
              color: isValid ? AppColors.richBlack : AppColors.sonicSilver,
            ),
          ),
        ],
      ),
    );
  }
}
