/// <reference types="vite/client" />

// Runtime configuration injected by the server
interface TerrateamConfig {
  // Analytics configuration
  ui_analytics?: 'enabled' | 'disabled';
  
  // Subscription UI mode
  ui_subscription?: 'disabled' | 'oss' | 'saas';
  
  // Maintenance mode
  maintenanceMode?: boolean | 'true' | 'false';
  maintenanceMessage?: string;

  // Stripe pricing table (SaaS billing mode only; both must be set to render it)
  stripe_publishable_key?: string;
  stripe_pricing_table_id?: string;
}

// Extend Window interface to include runtime config
declare global {
  interface Window {
    terrateamConfig?: TerrateamConfig;
  }
}