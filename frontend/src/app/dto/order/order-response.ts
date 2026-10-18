export interface Order {
    orderId: number;
    userId: number;
    items: OrderItem[];
    status: OrderStatus;
    totalAmount: number;
    createdAt: Date;
    recipientName: string;
    contactEmail: string;
    shippingAddress: string;
    contactPhone: string;

  }
  
  export interface OrderItem {
    id: number;
    menuItemId: number;
    name: string;
    quantity: number;
    price: number;
  }
  
  export enum OrderStatus {
    PENDING = 'PENDING',
    PREPARING = 'PREPARING',
    READY = 'READY',
    DELIVERED = 'DELIVERED',
    CANCELLED = 'CANCELLED'
  }
