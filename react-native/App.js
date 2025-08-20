import { StatusBar } from "expo-status-bar";
import React, { useMemo, useRef, useState } from "react";
import {
  StyleSheet,
  Text,
  View,
  TextInput,
  Pressable,
  ScrollView,
  Platform,
} from "react-native";
import DLocalDirectWebView from "./src/components/DLocalDirectWebView";

export default function App() {
  const bridgeRef = useRef(null);

  const [publicKey, setPublicKey] = useState("YOUR_PUBLIC_KEY");

  const [cardNumber, setCardNumber] = useState("4111111111111111");
  const [holderName, setHolderName] = useState("JOHN DOE");
  const [expMonth, setExpMonth] = useState("12");
  const [expYear, setExpYear] = useState("30");
  const [cvv, setCvv] = useState("123");

  const [bin, setBin] = useState("411111");
  const [amount, setAmount] = useState("100");
  const [currency, setCurrency] = useState("USD");
  const [country, setCountry] = useState("AR");

  const [log, setLog] = useState("");

  function onCreateToken() {
    const payload = {
      name: holderName,
      cvv,
      expirationMonth: expMonth,
      expirationYear: expYear,
      pan: cardNumber,
      country,
    };
    setLog("createToken: sending...");
    bridgeRef.current && bridgeRef.current.createToken(payload);
  }

  function onGetBinInfo() {
    // Typical usage: args = [bin, country]
    setLog("getBinInformation: sending...");
    bridgeRef.current && bridgeRef.current.getBinInformation(bin, country);
  }

  function onGetInstallments() {
    // Provide a flexible example argument order. Adjust to your account’s expected signature.
    // Required order: amount (number), currency (string), country (string), bin (string)
    setLog("getInstallmentsPlan: sending...");
    bridgeRef.current &&
      bridgeRef.current.getInstallmentsPlan(
        Number(amount),
        currency,
        country,
        bin
      );
  }

  function handleBridgeEvent(data) {
    try {
      if (data.type === "success") {
        setLog(JSON.stringify(data.payload, null, 2));
      } else if (data.type === "error") {
        try {
          setLog(
            "Error: " +
              JSON.stringify(
                data.payload || data,
                (key, value) => {
                  if (value instanceof Error) {
                    return {
                      message: value.message,
                      stack: value.stack,
                      name: value.name,
                    };
                  }
                  return value;
                },
                2
              )
          );
        } catch (e) {
          setLog("Error: " + String(data.payload || data));
        }
      } else {
        setLog(JSON.stringify(data, null, 2));
      }
    } catch (e) {
      setLog("Error: " + String(data && data.payload ? data.payload : data));
    }
  }

  return (
    <View style={styles.container}>
      <StatusBar style="auto" />
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.title}>dLocal Direct via WebView</Text>

        <Text style={styles.label}>Public Key</Text>
        <TextInput
          style={styles.input}
          value={publicKey}
          onChangeText={setPublicKey}
          placeholder="Public key"
        />

        <Text style={styles.section}>Create Token</Text>
        <TextInput
          style={styles.input}
          value={cardNumber}
          onChangeText={setCardNumber}
          placeholder="Card number"
          keyboardType="number-pad"
        />
        <TextInput
          style={styles.input}
          value={holderName}
          onChangeText={setHolderName}
          placeholder="Holder name"
        />
        <View style={styles.row}>
          <TextInput
            style={[styles.input, styles.half]}
            value={expMonth}
            onChangeText={setExpMonth}
            placeholder="MM"
            keyboardType="number-pad"
          />
          <TextInput
            style={[styles.input, styles.half]}
            value={expYear}
            onChangeText={setExpYear}
            placeholder="YYYY"
            keyboardType="number-pad"
          />
        </View>
        <TextInput
          style={styles.input}
          value={cvv}
          onChangeText={setCvv}
          placeholder="CVV"
          keyboardType="number-pad"
        />
        <Pressable style={styles.button} onPress={onCreateToken}>
          <Text style={styles.buttonText}>createToken</Text>
        </Pressable>

        <Text style={styles.section}>BIN & Installments</Text>
        <View style={styles.row}>
          <TextInput
            style={[styles.input, styles.half]}
            value={bin}
            onChangeText={setBin}
            placeholder="BIN"
            keyboardType="number-pad"
          />
          <TextInput
            style={[styles.input, styles.half]}
            value={country}
            onChangeText={setCountry}
            placeholder="Country (e.g., US)"
          />
        </View>
        <Pressable style={styles.button} onPress={onGetBinInfo}>
          <Text style={styles.buttonText}>getBinInformation</Text>
        </Pressable>

        <View style={styles.row}>
          <TextInput
            style={[styles.input, styles.half]}
            value={amount}
            onChangeText={setAmount}
            placeholder="Amount"
            keyboardType="decimal-pad"
          />
          <TextInput
            style={[styles.input, styles.half]}
            value={currency}
            onChangeText={setCurrency}
            placeholder="Currency (e.g., USD)"
          />
        </View>
        <Pressable style={styles.button} onPress={onGetInstallments}>
          <Text style={styles.buttonText}>getInstallmentsPlan</Text>
        </Pressable>

        <Text style={styles.section}>Result</Text>
        <View style={styles.logBox}>
          <Text style={styles.logText}>{log}</Text>
        </View>
      </ScrollView>

      <DLocalDirectWebView
        ref={bridgeRef}
        publicKey={publicKey}
        onEvent={handleBridgeEvent}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
  },
  content: {
    padding: 16,
    paddingBottom: 120,
  },
  title: {
    fontSize: 18,
    fontWeight: "600",
    marginBottom: 12,
  },
  label: {
    fontSize: 12,
    color: "#666",
    marginBottom: 4,
  },
  section: {
    marginTop: 16,
    marginBottom: 8,
    fontWeight: "600",
  },
  input: {
    borderWidth: 1,
    borderColor: "#e1e1e1",
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    marginBottom: 8,
  },
  row: {
    flexDirection: "row",
    gap: 8,
  },
  half: {
    flex: 1,
  },
  button: {
    backgroundColor: "#111827",
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: "center",
    marginBottom: 8,
  },
  buttonText: {
    color: "#fff",
    fontWeight: "600",
  },
  logBox: {
    minHeight: 80,
    borderWidth: 1,
    borderColor: "#e1e1e1",
    borderRadius: 8,
    padding: 12,
    backgroundColor: "#fafafa",
  },
  logText: {
    fontFamily: Platform.select({
      ios: "Menlo",
      android: "monospace",
      default: "Courier",
    }),
    fontSize: 12,
  },
  webview: {
    position: "absolute",
    bottom: 0,
    left: 0,
    right: 0,
    height: 1, // keep it mounted but not visible; we use it as a bridge
    opacity: 0.01,
  },
});
