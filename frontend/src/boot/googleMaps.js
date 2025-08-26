import { boot } from 'quasar/wrappers';

export default boot(async () => {
  const apiKey = import.meta.env.VITE_GOOGLE_MAPS_API_KEY;

  if (apiKey) {
    const script = document.createElement('script');
    script.async = true;
    script.defer = true;
    script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}`;
    document.head.appendChild(script);
  } else {
    console.error('Variável de ambiente VITE_GOOGLE_MAPS_KEY não definida!');
  }
});
