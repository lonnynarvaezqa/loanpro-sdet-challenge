# LoanPro Calculator – SDET Challenge

Este repositorio muestra cómo abordé un reto de calidad y pruebas para  CLI de cálculo aritmético distribuido como imagen Docker. 

El objetivo no fue forzar bugs ni buscar fallas artificiales, sino entender cómo se comporta el producto en escenarios reales, identificar riesgos que podrían pasar desapercibidos y pensar en pruebas que ayuden a prevenir problemas a futuro.

---

## 1. Resumen

Después de ejecutar pruebas funcionales y algunos eedge cases se ecncontró:

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
docker run --rm public.ecr.aws/l4q9w4c5/loanpro-calculator-cli 
add --5 3
```

```bash
docker run --rm public.ecr.aws/l4q9w4c5/loanpro-calculator-cli 
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

## 4. Matriz de Pruebas Ejecutadas

| ID    | Categoría | Caso                        | Resultado |
| ----- | --------- | --------------------------- | --------- |
| TC-01 | Funcional | add 2 3                     | OK        |
| TC-02 | Funcional | subtract 5 3                | OK        |
| TC-03 | Funcional | multiply 4 5                | OK        |
| TC-04 | Funcional | divide 10 2                 | OK        |
| TC-05 | Borde     | multiply 9999999999999999 2 | FAIL      |
| TC-06 | Input     | add a b                     | OK        |
| TC-07 | Input     | add --5 3                   | FAIL      |
| TC-08 | Input     | add +-5 3                   | FAIL      |
| TC-09 | Negativos | divide -10 -2               | OK        |
| TC-10 | Precisión | add 0.1 0.2                 | OK        |

---

## 5. Automatización

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

  output=$(docker run --rm $IMAGE $cmd 2>&1)

  if [[ "$output" == *"$expected"* ]]; then
    echo "✅ $desc"
  else
    echo "❌ $desc"
    echo "Expected to contain: $expected"
    echo "Got: $output"
    FAIL=1
  fi
}

run_test "Add integers" "add 2 3" "5"
run_test "Multiply large numbers" "multiply 9999999999999999 2" "20000000000000000"
run_test "Invalid numeric format" "add --5 3" "Invalid argument"

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
