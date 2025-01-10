#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT.h>

// Konfigurasi WiFi
const char* ssid = "SANTAI";
const char* password = "becakroda4";

// URL server Flask
const char* serverUrl = "https://186e-180-245-90-159.ngrok-free.app/data";

// Konfigurasi sensor DHT
#define DHTPIN 4
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

// Konfigurasi sensor gas
#define GAS_PIN 34

// Waktu delay
unsigned long previousMillis = 0;
const long interval = 5000; // 5 detik

void setup() {
  Serial.begin(115200);
  delay(1000);

  dht.begin();

  WiFi.begin(ssid, password);
  Serial.print("Menghubungkan ke WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.print(".");
  }
  Serial.println("\nTerhubung ke WiFi");
}

void loop() {
  unsigned long currentMillis = millis();
  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;

    if (WiFi.status() != WL_CONNECTED) {
      Serial.println("WiFi tidak terhubung. Mencoba menyambungkan kembali...");
      WiFi.begin(ssid, password);
      int retryCount = 0;
      while (WiFi.status() != WL_CONNECTED && retryCount < 10) {
        delay(1000);
        Serial.print(".");
        retryCount++;
      }
      if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\nWiFi berhasil terhubung kembali.");
      } else {
        Serial.println("\nGagal menghubungkan ke WiFi. Coba lagi nanti.");
        return;
      }
    }

    // Membaca nilai sensor
    float suhu = dht.readTemperature();
    float kelembapan = dht.readHumidity();
    int gasValue = analogRead(GAS_PIN);

    // Mengulang pengambilan data sensor jika gagal
    int retryCount = 0;
    while (isnan(suhu) || isnan(kelembapan)) {
      Serial.println("Gagal membaca data dari sensor DHT. Mencoba lagi...");
      suhu = dht.readTemperature();
      kelembapan = dht.readHumidity();
      retryCount++;
      if (retryCount >= 5) {
        Serial.println("Gagal membaca data setelah 5 percobaan. Melanjutkan loop berikutnya.");
        return;
      }
      delay(1000);
    }

    // Menampilkan data yang akan dikirim
    Serial.println("Mengirim data ke server:");
    Serial.printf("Suhu: %.2f °C\n", suhu);
    Serial.printf("Kelembapan: %.2f %%\n", kelembapan);
    Serial.printf("Gas: %d\n", gasValue);

    // Membuat HTTPClient
    HTTPClient http;
    http.begin(serverUrl);
    http.addHeader("Content-Type", "application/json");
    http.setTimeout(5000);

    // Membuat payload JSON
    String jsonPayload = "{\"sensor_value_temp\":" + String(suhu) +
                         ",\"sensor_value_humidity\":" + String(kelembapan) +
                         ",\"sensor_value_gas\":" + String(gasValue) + "}";

    // Mengirimkan data POST
    int httpResponseCode = http.POST(jsonPayload);
    
    if (httpResponseCode > 0) {
      Serial.printf("Data berhasil dikirim. HTTP Response: %d\n", httpResponseCode);
    } else {
      Serial.printf("Gagal mengirim data. Error: %s\n", http.errorToString(httpResponseCode).c_str());
    }

    // Menutup koneksi HTTP
    http.end();
  }
}
