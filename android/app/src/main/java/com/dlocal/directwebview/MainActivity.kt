package com.dlocal.directwebview

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.Toolbar
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
//        enableEdgeToEdge()
        setContentView(R.layout.activity_main)
        
        setupToolbar()
        setupNavigationButtons()
        
        // Handle system status bar insets for the main content area
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, 0, systemBars.right, systemBars.bottom)
            insets
        }
    }

    private fun setupToolbar() {
        val toolbar = findViewById<Toolbar>(R.id.toolbar)
        setSupportActionBar(toolbar)
        supportActionBar?.title = "dLocal Direct SDK"
        supportActionBar?.setDisplayHomeAsUpEnabled(false) // No back button on main screen
    }

    private fun setupNavigationButtons() {
        // Create Token navigation
        findViewById<Button>(R.id.btnCreateToken).setOnClickListener {
            val intent = Intent(this, CreateTokenActivity::class.java)
            startActivity(intent)
        }

        // Get Bin Information navigation
        findViewById<Button>(R.id.btnGetBinInfo).setOnClickListener {
            val intent = Intent(this, BinInfoActivity::class.java)
            startActivity(intent)
        }

        // Get Installments Plan navigation
        findViewById<Button>(R.id.btnGetInstallments).setOnClickListener {
            val intent = Intent(this, InstallmentsActivity::class.java)
            startActivity(intent)
        }
    }
}