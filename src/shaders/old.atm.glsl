#version 300 es
precision highp float;

uniform sampler2D u_PlanetColor;
uniform samplerCube u_StarsColor;

uniform vec3 u_SunDirection; // Нормализованный вектор.
uniform vec3 u_CameraLocation;

uniform vec4 u_AtmosphereInformation; // RADIUS_PLANET, RADIUS_ATMOSPHERE, AVANGE_DENSITY_RAY, AVANGE_DENSITY_MIE

uniform vec3 u_KRay; // K_RAY
uniform vec3 u_KMie; // K_MIE

uniform vec4 u_SunColor; // SUN_COLOR, SUN_INTENSITY
uniform float u_MieG; // MIE_G

in vec3 io_NormalXP;
in vec3 io_NormalXN;

in vec3 io_NormalYP;
in vec3 io_NormalYN;

in vec3 io_NormalZP;
in vec3 io_NormalZN;

out vec4 o_Color[6];

#define PI 3.1415926535
#define MAX_VALUE 1e10

#define STEP_COUNT_PRIMARY 96
#define STEP_COUNT_SECONDARY 8

// Обычный алгоритм рассчёта точек пересечения луча и сферы, но с учётом того что для origin находящегося внутри сферы - t0 будет равен 0.0:

vec2 intersection(vec3 origin, vec3 direction, float radius) {
    vec3 D = direction;
    vec3 L = vec3(0.0) - origin;

    float tca = dot(D, L);
    float d = dot(L, L) - (tca * tca);
    float R = radius * radius;

    if (d > R) {
        return vec2(MAX_VALUE, -MAX_VALUE);
    }

    float thc = sqrt(R - d);
    float t0 = tca - thc;
    float t1 = tca + thc;

    if (t0 > 0.0 || t1 > 0.0) {
        t0 = max(t0, 0.0);
        t1 = max(t1, 0.0);

        return vec2(min(t0, t1), max(t0, t1));
    }

    return vec2(MAX_VALUE, -MAX_VALUE);
}

// Рассчитываем фазу для ray:

float calculatePhaseRay(float cosineSquare) {
    return 0.75 * (1.0 + cosineSquare);
}

// Рассчитываем фазу для mie:

float calculatePhaseMie(float cosineSquare, float cosine) {

    float RADIUS_PLANET     = u_AtmosphereInformation.x;
    float RADIUS_ATMOSPHERE = u_AtmosphereInformation.y;

    float AVANGE_DENSITY_RAY = u_AtmosphereInformation.z;
    float AVANGE_DENSITY_MIE = u_AtmosphereInformation.w;

    vec3 K_RAY = u_KRay;
    vec3 K_MIE = u_KMie;

    vec3  SUN_COLOR     = u_SunColor.rgb;
    float SUN_INTENSITY = u_SunColor.a;

    float MIE_G = u_MieG;

    float vA = 3.0 * (1.0 - MIE_G * MIE_G);
    float vB = 2.0 * (2.0 - MIE_G * MIE_G);

    float vC = 1.0 + cosineSquare;
    float vD = pow(1.0 + MIE_G * MIE_G - 2.0 * MIE_G * cosine, 1.5);

    return (vA / vB) * (vC / vD);
}

// Рассчёт внтуреннего интеграла (оптической глубины) отдельно для ray и mie:

void calculateInternalIntegral(vec3 rayOrigin, vec3 rayDirection, out float depthRay, out float depthMie) {

    float RADIUS_PLANET      = u_AtmosphereInformation.x;
    float RADIUS_ATMOSPHERE  = u_AtmosphereInformation.y;
    float AVANGE_DENSITY_RAY = u_AtmosphereInformation.z;
    float AVANGE_DENSITY_MIE = u_AtmosphereInformation.w;
    vec3  K_RAY              = u_KRay;
    vec3  K_MIE              = u_KMie;
    vec3  SUN_COLOR          = u_SunColor.rgb;
    float SUN_INTENSITY      = u_SunColor.a;
    float MIE_G              = u_MieG;

    float rayStepLength = intersection(rayOrigin, rayDirection, RADIUS_ATMOSPHERE).y / float(STEP_COUNT_SECONDARY);
    vec3  rayStep = rayDirection * rayStepLength;
    vec3  rayStepCurrent = rayOrigin + rayStep * 0.5;

    depthRay = 0.0;
    depthMie = 0.0;

    for (int i = 0; i < STEP_COUNT_SECONDARY; i++) {
        float currentHeight = length(rayStepCurrent) - RADIUS_PLANET;

        depthRay += exp(-currentHeight / AVANGE_DENSITY_RAY) * rayStepLength;
        depthMie += exp(-currentHeight / AVANGE_DENSITY_MIE) * rayStepLength;

        rayStepCurrent += rayStep;
    }
}

vec3 calculateColor(vec3 rayOrigin, vec3 rayDirection, vec3 sunDirection) {

    float RADIUS_PLANET      = u_AtmosphereInformation.x;
    float RADIUS_ATMOSPHERE  = u_AtmosphereInformation.y;
    float AVANGE_DENSITY_RAY = u_AtmosphereInformation.z;
    float AVANGE_DENSITY_MIE = u_AtmosphereInformation.w;
    vec3  K_RAY              = u_KRay;
    vec3  K_MIE              = u_KMie;
    vec3  SUN_COLOR          = u_SunColor.rgb;
    float SUN_INTENSITY      = u_SunColor.a;
    float MIE_G              = u_MieG;

    // Находим точки пересечения луча и атмосферы:

    vec2 aip = intersection(rayOrigin, rayDirection, RADIUS_ATMOSPHERE);
    if (aip.x > aip.y) {
        return texture(u_StarsColor, rayDirection).rgb; // Если мы промахнулись мимо атмосферы - просто выводим цвет из текстуры звёзд.
    }

    // Находим точки пересечения луча и планеты:

    vec2 pip = intersection(rayOrigin, rayDirection, RADIUS_PLANET);
    aip.y = min(aip.y, pip.x);

    float primaryRayStepLength = (aip.y - aip.x) / float(STEP_COUNT_PRIMARY);
    vec3  primaryRayStep = rayDirection * primaryRayStepLength;
    vec3  primaryRayStepCurrent = rayOrigin + rayDirection * aip.x + primaryRayStep * 0.5;

    vec3 finalRay = vec3(0.0);
    vec3 finalMie = vec3(0.0);

    float primaryDepthRay = 0.0;
    float primaryDepthMie = 0.0;

    vec3 attenuation = vec3(0.0); // Вместо рассчёта света отражёного от поверхности можно воспользоваться последним значением attenuation.

    for (int i = 0; i < STEP_COUNT_PRIMARY; i++) {
        float primaryHeight = length(primaryRayStepCurrent) - RADIUS_PLANET;

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
    vec3 planetColor = vec3(0.0);

    // TODO - подумать над зтим блоком:

    if (aip.y == pip.x) {
        // Рассчитываем цвет поверхности:

        vec3 location = normalize(rayOrigin + rayDirection * pip.x);
        vec2 coordinates = vec2(asin(location.y) / PI + 0.5, (atan(location.x, location.z) / PI + 1.0) * 0.5);

        planetColor = texture(u_PlanetColor, coordinates.yx).rgb * attenuation;
    }
    else {
        // Рассчитываем цвет звёзд видимых через атмосферу:

        vec3 value = exp(-4.0 * PI * (K_RAY * primaryDepthRay + K_MIE * primaryDepthMie));
        planetColor = texture(u_StarsColor, rayDirection).rgb * value;
    }

    return atmosphereColor + planetColor;
}

void main() {
    o_Color[0] = vec4(calculateColor(u_CameraLocation, normalize(io_NormalXP), normalize(u_SunDirection)), 1.0);
    o_Color[1] = vec4(calculateColor(u_CameraLocation, normalize(io_NormalXN), normalize(u_SunDirection)), 1.0);
    o_Color[2] = vec4(calculateColor(u_CameraLocation, normalize(io_NormalYP), normalize(u_SunDirection)), 1.0);
    o_Color[3] = vec4(calculateColor(u_CameraLocation, normalize(io_NormalYN), normalize(u_SunDirection)), 1.0);
    // o_Color[4] = vec4(calculateColor(u_CameraLocation, normalize(io_NormalZP), normalize(u_SunDirection)), 1.0);
    o_Color[5] = vec4(calculateColor(u_CameraLocation, normalize(io_NormalZN), normalize(u_SunDirection)), 1.0);
}
