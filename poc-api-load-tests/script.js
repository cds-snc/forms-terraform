import { sleep } from 'k6';
import http from 'k6/http';

// See https://k6.io/docs/using-k6/k6-options/
export const options = {
  stages: [
    { duration: '10s', target: 10 },   // Ramp up to 10 VUs in 10 seconds
    { duration: '20s', target: 100 },   // Ramp up to 100 VUs in 20 seconds
    { duration: '20s', target: 150 },   // Ramp up to 150 VUs in 20 seconds
    { duration: '1m', target: 200 },   // Stay at 200 VUs for 1 minute
    { duration: '20s', target: 30 },    // Ramp down to 30 VUs in 20 seconds
  ],
  thresholds: {
    'http_req_failed': ['rate<0.01'], // http errors should be less than 1%
    'http_req_duration': ['p(50)<=100', 'p(75)<=200', 'p(90)<=300', 'p(99)<=500'],
  },
}

export default function () {
  http.get('https://test.k6.io');
}