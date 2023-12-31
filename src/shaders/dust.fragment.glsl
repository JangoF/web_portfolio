in vec3 cameraToVertex;

void main() {
  gl_FragColor = vec4(vec3(0.75), 50. / length(cameraToVertex));
}
