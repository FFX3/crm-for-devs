use clap::Parser;
use postgrest::Postgrest;
use dotenv::dotenv;
use std::env::var;
use go_true::{EmailOrPhone, Api as GoTrueApi};

/// Simple program to greet a person
#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    /// Name of the person to greet
    #[arg(short, long)]
    email: String,

    #[arg(short, long)]
    password: String,
}

#[tokio::main]
async fn main() {
    dotenv().ok(); 
    let args = Args::parse();

    println!("{:?}", args);

    let anon_key = var("SUPABASE_ANON_KEY").expect("set the service role key");
    let domain = var("SUPABASE_URL").expect("set the rest api domain");
    let go_true_api = GoTrueApi::new(format!("{}/auth/v1", domain))
        .insert_header("apikey", anon_key);

    let session = go_true_api
        .sign_in(EmailOrPhone::Email(args.email), &args.password)
        .await.expect("Couldn't create GoTrue session");

    let result = client(session.access_token)
        .from("contacts")
        .select("id")
        .execute()
        .await;

    match result {
        Err(error) => {
            println!("Error: {:?}", error);
        },
        Ok(data) => {
            println!("success: {:?}", data.text().await);
        }
    }

}


fn client(access_token: String) -> Postgrest {
    dotenv().ok(); 
    let domain = var("SUPABASE_URL").expect("set the rest api domain");
    let anon_key = var("SUPABASE_ANON_KEY").expect("set the service role key");

    Postgrest::new(format!("{}/rest/v1", domain))
        .insert_header("apikey", anon_key)
        .insert_header("Authorization", format!("Bearer {}", access_token))

}

