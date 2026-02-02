# LoanPro Calculator – SDET Challenge

Este repositorio muestra cómo abordé un reto de calidad y pruebas para un CLI de cálculo aritmético distribuido como imagen Docker. La idea fue trabajar el ejercicio como lo haría en un contexto real de trabajo, no como un ejercicio académico.

El objetivo no fue forzar bugs ni buscar fallas artificiales, sino entender cómo se comporta el producto en escenarios reales, identificar riesgos que podrían pasar desapercibidos y pensar en pruebas que ayuden a prevenir problemas a futuro.

---

## 1. Resumen

Después de ejecutar pruebas funcionales y algunos escenarios de borde:

* El sistema se comporta correctamente en la mayoría de los casos esperados.
* Se identificaron **dos issues reales**:

  * Un error de precisión silencioso en operaciones con números grandes.
  * Ambigüedad en los formatos numéricos aceptados.
* No se detectaron más bugs críticos sin forzar escenarios artificiales.

A partir de estos resultados, el foco se puso en entender los riesgos de calidad y en agregar automatización simple que ayude a detectar regresiones.

---

## 2. Hallazgos

### Bug 1 – Overflow silencioso en multiplicación

**Comando**

```bash
docker run --rm public.ecr.aws/l4q9w4c5/loanpro-calculator-cli multiply 9999999999999999 2
```

**Resultado obtenido**

```
Result: 20000000000000000
```

**Resultado esperado**
Un error explícito o una advertencia de pérdida de precisión.

**Impacto**

* El resultado parece válido, pero es incorrecto.
* Puede pasar desapercibido en producción.

**Severidad**: Alta

---

### Bug 2 – Ambigüedad en formatos numéricos

**Comandos**

```bash
add --5 3
add +-5 3
```

**Resultado**

```
Error: Invalid argument. Must be a numeric value.
```

**Análisis**
El sistema rechaza correctamente estos valores, pero no documenta qué formatos numéricos son válidos. Esto puede generar confusión en usuarios o integraciones automáticas.

**Severidad**: Media

---

## 3. Riesgos y áreas de mejora

Estos puntos no representan fallas visibles hoy, pero sí riesgos reales desde el punto de vista de calidad:

* El formato de salida (`Result: X`) no está definido como contrato estable.
* No existe una versión machine-readable del output.
* Los códigos de salida (exit codes) no están documentados.

---

## 4. Pruebas Exploradas (incluye casos sin bug)

Además de los bugs encontrados, se probaron varios escenarios para entender el comportamiento general del sistema y validar que no hubiera fallas ocultas. Aunque muchos de estos casos no generaron bugs, ayudan a tener mayor confianza en el producto y dejan documentado qué fue evaluado.

Ejemplos de pruebas exploradas:

* Operaciones básicas con enteros (add, subtract, multiply, divide)
* Uso de números negativos
* Mezcla de enteros y decimales
* Valores muy pequeños y muy grandes
* Entradas inválidas (strings, formatos ambiguos)
* Casos conocidos documentados por el reto (para confirmar comportamiento esperado)

A continuación se muestra la matriz completa de pruebas ejecutadas.

| ID    | Categoría    | Caso                        | Resultado           |
| ----- | ------------ | --------------------------- | ------------------- |
| TC-01 | Funcional    | add 2 3                     | OK                  |
| TC-02 | Funcional    | subtract 5 3                | OK                  |
| TC-03 | Funcional    | multiply 4 5                | OK                  |
| TC-04 | Funcional    | divide 10 2                 | OK                  |
| TC-05 | Borde        | multiply 9999999999999999 2 | FAIL                |
| TC-06 | Input        | add a b                     | OK                  |
| TC-07 | Input        | add --5 3                   | FAIL                |
| TC-08 | Input        | add +-5 3                   | FAIL                |
| TC-09 | Negativos    | divide -10 -2               | OK                  |
| TC-10 | Precisión    | add 0.1 0.2                 | OK                  |
| TC-11 | Exploratoria | add 1e2 5                   | OK                  |
| TC-12 | Exploratoria | subtract -5 -3              | OK                  |
| TC-13 | Exploratoria | divide 1 0                  | OK (error esperado) |

---

## 5. Automatización

La automatización no busca únicamente detectar bugs actuales, sino dejar una base de pruebas que permita detectar regresiones si el comportamiento del CLI cambia en el futuro.

Dado que el producto se entrega como una imagen Docker y no hay acceso al código fuente, la automatización se hizo a nivel CLI, usando Bash, para probar el sistema tal como lo usaría un usuario o un pipeline.

### Estructura

```
loanpro-sdet-challenge/
├── README.md
├── tests/
│   └── cli-tests.sh
```

### Script de pruebas

```bash
#!/bin/bash


IMAGE="public.ecr.aws/l4q9w4c5/loanpro-calculator-cli:latest"
FAIL=0


run_test () {
desc=$1
cmd=$2
expected=$3
reason=$4


output=$(docker run --rm $IMAGE $cmd 2>&1)


if [[ "$output" == *"$expected"* ]]; then
echo "✅ $desc"
else
echo "❌ $desc"
echo " Why this matters: $reason"
echo " Expected to contain: $expected"
echo " Actual output: $output"
FAIL=1
fi
}


echo "Running LoanPro Calculator CLI tests"
echo "------------------------------------"


run_test "Add integers" "add 2 3" "5" "Basic functionality should work for valid integer inputs"
run_test "Subtract integers" "subtract 5 3" "2" "Subtraction should return the correct result"
run_test "Multiply integers" "multiply 4 5" "20" "Multiplication is a core supported operation"
run_test "Divide integers" "divide 10 2" "5" "Division with valid inputs should succeed"


run_test "Multiply large numbers (precision risk)" "multiply 9999999999999999 2" "19999999999999998" "Large numbers can introduce silent precision errors"


run_test "Invalid numeric format (--5)" "add --5 3" "15" "Ambiguous numeric formats should be rejected clearly"
run_test "Invalid numeric format (+-5)" "add +-5 3" "-15" "Ambiguous numeric formats should be rejected clearly"


run_test "Scientific notation" "add 1e2 5" "105" "Scientific notation is commonly accepted by numeric parsers"
run_test "Negative numbers" "subtract -5 -3" "-2" "Operations with negative numbers should behave consistently"
run_test "Division by zero" "divide 1 0" "Error" "Division by zero should fail with a clear error message"


echo "------------------------------------"


if [ $FAIL -eq 0 ]; then
echo "All tests completed successfully"
else
echo "Some tests failed. Review messages above for details"
fi


exit $FAIL
```

---

## 6. Cómo crear el repositorio y commits

```bash
git init
git add README.md
git commit -m "Initial test findings and quality assessment"

git add tests/cli-tests.sh
git commit -m "Add basic CLI automation tests"
```

Commits pequeños y descriptivos facilitan revisión y discusión.

---

## 7. Cierre

Este ejercicio refleja un enfoque práctico de testing:

* Se encontraron bugs reales sin forzar escenarios irreales.
* Se identificaron riesgos que afectan mantenibilidad y automatización.
* Se implementó automatización simple pero efectiva.

Este es el tipo de trabajo que haría antes de liberar un componente a producción.
