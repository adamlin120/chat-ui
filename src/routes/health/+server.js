export async function GET() {
    return new Response(JSON.stringify({ 
        status: 'healthy', 
        timestamp: new Date().toISOString(),
        region: 'ap-northeast-1'
    }), {
        headers: {
            'content-type': 'application/json'
        }
    });
}
