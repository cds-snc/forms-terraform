interface ApiTest {
  name: string;
  run(): Promise<void>;
}
