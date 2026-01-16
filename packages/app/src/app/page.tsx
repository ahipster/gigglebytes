export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-900 to-gray-800 text-white">
      <main className="container mx-auto px-4 py-16">
        <div className="text-center mb-16">
          <h1 className="text-5xl font-bold mb-4">GRIP</h1>
          <p className="text-xl text-gray-300">
            Global Registry Intelligence Platform
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-8 max-w-4xl mx-auto">
          <div className="bg-gray-800 p-6 rounded-lg border border-gray-700">
            <h2 className="text-xl font-semibold mb-2">135+ Registries</h2>
            <p className="text-gray-400">
              Collect legal entity data from national business, tax, and financial registries worldwide.
            </p>
          </div>

          <div className="bg-gray-800 p-6 rounded-lg border border-gray-700">
            <h2 className="text-xl font-semibold mb-2">Master Entity Records</h2>
            <p className="text-gray-400">
              Single source of truth with bi-temporal tracking and full data lineage.
            </p>
          </div>

          <div className="bg-gray-800 p-6 rounded-lg border border-gray-700">
            <h2 className="text-xl font-semibold mb-2">Entity Resolution</h2>
            <p className="text-gray-400">
              Automated matching with 85%+ STP rate and configurable survivorship rules.
            </p>
          </div>
        </div>

        <div className="text-center mt-16">
          <p className="text-gray-500 text-sm">v2.0 - In Development</p>
        </div>
      </main>
    </div>
  );
}
