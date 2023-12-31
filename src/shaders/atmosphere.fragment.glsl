uniform vec3 sunDirection;
in vec3 cameraToVertex;

// const float AVANGE_DENSITY_RAY = 0.4;
// const float AVANGE_DENSITY_MIE = 0.1;

const vec3 K_RAY = vec3(0.1, 0.2, 0.4);
const vec3 K_MIE = vec3(0.02);
const float MIE_G = -0.75f;

const vec3 SUN_COLOR = vec3(1);
const float SUN_INTENSITY = 10.0f;

const int PRIMARY_STEP_COUNT = 16;
const int SECONDARY_STEP_COUNT = 8;

vec2 raySphereIntersection(vec3 rayOrigin, vec3 rayDirection, float sphereRadius) {
  vec3 toSphere = rayOrigin - vec3(0.0);

  float a = dot(rayDirection, rayDirection);
  float b = 2.0 * dot(toSphere, rayDirection);
  float c = dot(toSphere, toSphere) - (sphereRadius * sphereRadius);

  float discriminant = b * b - 4.0 * a * c;
  if (discriminant < 0.0) {
    return vec2(INFINITY, -INFINITY);
  }

  float sqrtDiscriminant = sqrt(discriminant);
  float t0 = (-b - sqrtDiscriminant) / (2.0 * a);
  float t1 = (-b + sqrtDiscriminant) / (2.0 * a);

  if (t0 > 0.0 || t1 > 0.0) {
    t0 = max(t0, 0.0);
    t1 = max(t1, 0.0);

    return vec2(min(t0, t1), max(t0, t1));
  }
  
  return vec2(INFINITY, -INFINITY);
}

// Рассчитываем фазу для ray:

float calculatePhaseRay(float cosineSquare) {
    return 0.75 * (1.0 + cosineSquare);
}

// Рассчитываем фазу для mie:

float calculatePhaseMie(float cosineSquare, float cosine) {
  float vA = 3.0 * (1.0 - MIE_G * MIE_G);
  float vB = 2.0 * (2.0 - MIE_G * MIE_G);

  float vC = 1.0 + cosineSquare;
  float vD = pow(1.0 + MIE_G * MIE_G - 2.0 * MIE_G * cosine, 1.5);

  return (vA / vB) * (vC / vD);
}

void calculateInternalIntegral(vec3 rayOrigin, vec3 rayDirection, out float depthRay, out float depthMie) {
  // Вычисление длины шага
  float rayStepLength = raySphereIntersection(rayOrigin, rayDirection, ATMOSPHERE_RADIUS).y / float(SECONDARY_STEP_COUNT);
  vec3 rayStep = rayDirection * rayStepLength;
  vec3 rayStepCurrent = rayOrigin + rayStep * 0.5;

  // Инициализация глубины для ray и mie
  depthRay = 0.0;
  depthMie = 0.0;

  // Итерация по шагам
  for (int i = 0; i < SECONDARY_STEP_COUNT; i++) {
    // Вычисление текущей высоты над поверхностью планеты
    float currentHeight = length(rayStepCurrent) - PLANET_RADIUS;

    // Интеграция для компонента ray
    depthRay += exp(-currentHeight / AVANGE_DENSITY_RAY) * rayStepLength;

    // Интеграция для компонента mie
    depthMie += exp(-currentHeight / AVANGE_DENSITY_MIE) * rayStepLength;

    // Переход к следующему шагу
    rayStepCurrent += rayStep;
  }
}

vec4 calculateColor(vec3 rayOrigin, vec3 rayDirection, vec3 sunDirection) {
  vec2 atmosphereIntersectionPoint = raySphereIntersection(rayOrigin, rayDirection, ATMOSPHERE_RADIUS);
  if (atmosphereIntersectionPoint.x > atmosphereIntersectionPoint.y) {
    return vec4(0.);
  }

  float alpha = 1.0;
  vec2 planetIntersectionPoint = raySphereIntersection(rayOrigin, rayDirection, PLANET_RADIUS);

  if (planetIntersectionPoint.x > planetIntersectionPoint.y) {
    alpha = atmosphereIntersectionPoint.y - atmosphereIntersectionPoint.x;
  }

  vec2 segment = vec2(atmosphereIntersectionPoint.x, min(atmosphereIntersectionPoint.y, planetIntersectionPoint.x));

  float primaryRayStepLength = (segment.y - segment.x) / float(PRIMARY_STEP_COUNT);
  vec3  primaryRayStep = rayDirection * primaryRayStepLength;
  vec3  primaryRayStepCurrent = rayOrigin + rayDirection * segment.x + primaryRayStep * 0.5;

  float primaryDepthRay = 0.0;
  float primaryDepthMie = 0.0;

  vec3 attenuation = vec3(0.0); // Вместо рассчёта света отражёного от поверхности можно воспользоваться последним значением attenuation.

  vec3 finalRay = vec3(0.0);
  vec3 finalMie = vec3(0.0);

  for (int i = 0; i < PRIMARY_STEP_COUNT; i++) {
    float primaryHeight = length(primaryRayStepCurrent) - PLANET_RADIUS;

    float primaryDepthRayCurrent = exp(-primaryHeight / AVANGE_DENSITY_RAY) * primaryRayStepLength;
    float primaryDepthMieCurrent = exp(-primaryHeight / AVANGE_DENSITY_MIE) * primaryRayStepLength;

    primaryDepthRay += primaryDepthRayCurrent;
    primaryDepthMie += primaryDepthMieCurrent;

    float secondaryDepthRay = 0.0;
    float secondaryDepthMie = 0.0;

    calculateInternalIntegral(primaryRayStepCurrent, sunDirection, secondaryDepthRay, secondaryDepthMie);

    attenuation = exp(-4.0 * PI * (K_RAY * (primaryDepthRay + secondaryDepthRay) + K_MIE * (primaryDepthMie + secondaryDepthMie)));

    finalRay += primaryDepthRayCurrent * attenuation;
    finalMie += primaryDepthMieCurrent * attenuation;

    primaryRayStepCurrent += primaryRayStep;
  }

  float cosine = dot(rayDirection, -sunDirection);
  float cosineSquare = cosine * cosine;

  float phaseRay = calculatePhaseRay(cosineSquare);
  float phaseMie = calculatePhaseMie(cosineSquare, cosine);

  vec3 atmosphereColor = SUN_COLOR * SUN_INTENSITY * (K_RAY * phaseRay * finalRay + K_MIE * phaseMie * finalMie);

  return vec4(atmosphereColor, alpha) + vec4(.063, .094, .122, 1. - alpha);
}

void main() {
  gl_FragColor = calculateColor(cameraPosition, normalize(cameraToVertex), normalize(sunDirection));
}

























