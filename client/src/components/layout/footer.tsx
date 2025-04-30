export default function Footer() {
  return (
    <footer className="bg-white border-t mt-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <div className="flex flex-col items-center justify-center">
          <div className="mt-2 text-center">
            <p className="text-sm text-gray-500">
              &copy; {new Date().getFullYear()} Team Rankings System. All rights reserved.
            </p>
          </div>
        </div>
      </div>
    </footer>
  );
}
